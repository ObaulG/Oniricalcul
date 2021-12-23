extends Node2D

var POPUPCLASS = load("res://UI/PopUpNotification.tscn")

const ROUND_TIME = 33.0
const PREROUND_TIME = 5.0
const SHOPPING_TIME = 15.0

enum STATE{
	WAITING_EVERYONE = 1,
	PREROUND = 2,
	ROUND = 3,
	SHOPPING = 4,
	ENDED = 5
}
var REVERSE_STATE = {
	1: STATE.WAITING_EVERYONE,
	2: STATE.PREROUND,
	3: STATE.ROUND,
	4: STATE.SHOPPING,
	5: STATE.ENDED
}
signal domain_answer_response(id_domain, good_answer)
signal new_incantations_received(L)
signal game_state_changed(new_state)
signal changing_stance_command(new_stance)

#to avoid conflict between client ids and bot ids
var game_id: int
var clients_ready_to_play = []
var rng = RandomNumberGenerator.new()
var round_counter: int
var operation_factory: OperationFactory

#duration of the game
var game_time: float

#current state
var state

var round_time: float
var preround_time: float
var shopping_time: float

#data that can't be stored because bots don't have
#bonus menu
var bot_game_data = {}
#stored by the server. keys and values are pids
var targets: Dictionary
var game_stats = []

var base_data

var total_meteor_sent:= 0
#The field game, with at least 2 players.
#Later, we might have a 3+ multiplayer mode,
#so we don't always update the screen.
onready var my_domain = $main_player_domain
onready var bonus_window = $bonus_menu
onready var enemy_domains = $enemy
onready var round_timer = $round_time_remaining
onready var input_handler = $InputHandler
onready var operation_display = $OperationDisplayBasic
onready var scene_transition_rect = $SceneTransitionRect
onready var time_display = $TimeLeftDisplay
onready var popup_nodes = $PopUps
onready var state_label = $state_label
onready var ready_label = $players_ready

# Called when the node enters the scene tree for the first time.
func _ready():
	game_id = Gamestate.player_info["game_id"]
	# Connect event handler to the player_list_changed signal
	network.connect("player_list_changed", self, "_on_player_list_changed")
	
	#We must remove the player if he leaves
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	
	#or stop the game if we are disconnected
	get_tree().connect("server_disconnected", self, "_on_disconnected_from_server")
	
	# Must act if disconnected from the server
	network.connect("disconnected", self, "_on_disconnected")
	
	operation_factory = OperationFactory.new()
	print("operation factory generated")
	
	state = STATE.WAITING_EVERYONE
	ready_label.text = "Joueurs prêts: 0 / " + str(len(clients_ready_to_play))
	
	round_time = ROUND_TIME
	preround_time = PREROUND_TIME
	shopping_time = SHOPPING_TIME

	my_domain.initialise(network.players[Gamestate.player_info["net_id"]])
	connect("domain_answer_response", my_domain, "_on_GameFieldMulti_domain_answer_response")
	
	print("my domain is initialised")
	
	my_domain.base_data.spellbook.connect("meteor_invocation", self, "_on_spellbook_meteor_invocation")
	my_domain.base_data.spellbook.connect("defense_command", self, "_on_spellbook_defense_command")
	my_domain.base_data.spellbook.connect("low_incantation_stock", self, "_on_spellbook_low_incantations_stock")
	my_domain.base_data.spellbook.connect("incantation_has_changed", self, "_on_spellbook_incantation_has_changed")
	my_domain.base_data.spellbook.connect("incantation_progress_changed", self, "_on_spellbook_incantation_progress_changed")
	my_domain.base_data.spellbook.connect("potential_value_changed", self, "_on_spellbook_potential_value_changed")
	my_domain.base_data.spellbook.connect("defense_power_changed", self, "_on_spellbook_defense_power_changed")
	my_domain.base_data.spellbook.connect("money_value_has_changed", self, "_on_spellbook_money_value_has_changed")
	my_domain.base_data.spellbook.connect("operation_to_display_has_changed", self, "_on_spellbook_operation_to_display_has_changed")
	my_domain.base_data.connect("hp_value_changed", self, "_on_base_data_hp_value_changed")
	my_domain.domain_field.connect("meteor_destroyed", self, "_on_domain_field_meteor_destroyed")
	my_domain.domain_field.connect("meteor_impact", self, "_on_domain_field_meteor_impact")
	my_domain.domain_field.connect("meteor_hp_changed", self, "_on_domain_field_meteor_hp_changed")
	my_domain.domain_field.connect("magic_projectile_end_with_power_left", self, "_on_magic_projectile_end_with_power_left")
	#everyone has already the data to spawn every single player
	spawn_players()
	print("all players have been initialised")
	
	targets = {}
	time_display.set_min_value(0)
	time_display.set_max_value(60)
	round_timer.start(60)

	if get_tree().is_network_server():
		print("Generate operations for server player")
		generate_new_incantation_operations(my_domain.game_id, 3)
	else:
		rpc_id(1,"generate_new_incantation_operations", my_domain.game_id, 3)
	print("my operations are generated")
	
	bonus_window.game_id = game_id
	#pause_mode = true
	
func _process(delta):
	if not pause_mode:
		game_time += delta
	time_display.set_new_value(round_timer.time_left)
	bonus_window.set_time(round_timer.time_left)
	
func _on_player_disconnected(pinfo):
	pass
	#remove the player from the scene
	var domain_to_remove = get_domain_by_gid(pinfo["game_id"])
	domain_to_remove.queue_free()
	
func _on_disconnected_from_server():
	leave_game()

func leave_game():
	scene_transition_rect.change_scene("res://scenes/titlescreen/title.tscn")
	
remote func spawn_players():
	for id in network.players:
		if id != Gamestate.player_info["net_id"]:
			generate_actor(network.players[id])
	for id in network.bots:
		generate_actor(network.bots[id])
		
	print("All actors generated")
	
#called to tell everyone the game is about to start
remote func client_ready(gid: int):
	clients_ready_to_play.append(gid)
	ready_label.text = "Joueurs prêts: " + str(len(clients_ready_to_play)) +" / " + str(network.get_total_players_entities())
	if get_tree().is_network_server():
		for id in network.players:
			if id != 1:
				rpc_id(id, "client_ready", gid)
				
		#might cause problems ?
		if len(clients_ready_to_play) >= network.get_total_players_entities():
			rpc("game_about_to_start")

#note: meteor and projectile casts are only visual in clients: if it is display
#on a basedomaindisplay, then it's not the main character so they should
#not send data from other players.

func generate_actor(pinfo):
	# Load the scene and create an instance
	var pclass
	if pinfo["is_bot"]:
		pclass = load("res://multiplayer/BaseDomainDisplay.tscn")
	else:
		pclass = load("res://multiplayer/PlayerDomain.tscn")
	var nactor = pclass.instance()
	
	# add the actor into the world
	enemy_domains.add_child(nactor)
	# domain initialization
	nactor.initialise(pinfo)
	
	# If this actor does not belong to the server, change the node name and network master accordingly
	if (pinfo["net_id"] != 1):
		nactor.set_network_master(pinfo["net_id"])
	
	nactor.set_name(str(pinfo["net_id"]))
	if pinfo["is_bot"]:
		bot_game_data[pinfo["game_id"]] = {}
		bot_game_data[pinfo["game_id"]]["shop_operations"] = []
		nactor.set_name("bot_"+str(pinfo["net_id"]))
		var bot_diff = pinfo["bot_diff"]
		nactor.ai_node.set_hardness(bot_diff)
		nactor.activate_AI()

	#we add connections (elimination, meteor casts, projectile casts, etc)
	#elimination signal
	nactor.base_data.connect("eliminated", self, "_on_enemy_elimination")
	connect("domain_answer_response", nactor, "_on_GameFieldMulti_domain_answer_response")

	if get_tree().is_network_server():
		generate_new_incantation_operations(pinfo["game_id"], 3)
		
	#send signal to tell everyone this bot is ready
	if get_tree().is_network_server() and pinfo["is_bot"]:
		nactor.base_data.spellbook.connect("meteor_invocation", self, "_on_spellbook_meteor_invocation")
		nactor.base_data.spellbook.connect("defense_command", self, "_on_spellbook_defense_command")
		nactor.base_data.spellbook.connect("low_incantation_stock", self, "_on_spellbook_low_incantations_stock")
		nactor.base_data.spellbook.connect("incantation_has_changed", self, "_on_spellbook_incantation_has_changed")
		nactor.base_data.spellbook.connect("potential_value_changed", self, "_on_spellbook_potential_value_changed")
		nactor.base_data.spellbook.connect("defense_power_changed", self, "_on_spellbook_defense_power_changed")
		
		nactor.base_data.connect("hp_value_changed", self, "_on_base_data_hp_value_changed")
		nactor.domain_field.connect("meteor_destroyed", self, "_on_domain_field_meteor_destroyed")
		nactor.domain_field.connect("meteor_impact", self, "_on_domain_field_meteor_impact")
		nactor.domain_field.connect("meteor_hp_changed", self, "_on_domain_field_meteor_hp_changed")

		nactor.base_data.spellbook.connect("money_value_has_changed", bonus_window, "_on_spellbook_money_value_has_changed")
		client_ready(pinfo["game_id"])
	else:
		rpc_id(1, "client_ready", pinfo["game_id"])
		
#called to tell all clients the game can start
remotesync func game_about_to_start():
	pause_mode = false
	changing_state(STATE.PREROUND)
	
	#showing 1st operation
	my_domain.base_data.spellbook.charge_new_incantation()
	operation_display.change_operation_display(my_domain.base_data.spellbook.get_current_operation())
	my_domain.update_all_stats_display()
	
	for domain in enemy_domains.get_children():
		if domain.is_bot():
			domain.base_data.spellbook.charge_new_incantation()
			domain.update_all_stats_display()
#we are not supposed to jump states, but just in case,
#we give the new state as an argument
#TO BE CONTINUED
remotesync func changing_state(new_state):
	round_timer.stop()
	if get_tree().is_network_server():
		match(new_state):
			STATE.PREROUND:
				new_round()
			STATE.ROUND:
				activate_AI_for_round_time()
			STATE.SHOPPING:
				pause_AI()
				#will call rpc in all clients
				generate_all_shop_operations()
			STATE.ENDED:
				pause_AI()
		for id in network.players:
			if id != 1:
				rpc_id(id, "changing_state", new_state)
		
	state = new_state
	round_timer.stop()
	match(state):
		STATE.PREROUND:
			round_timer.start(preround_time)
			time_display.set_max_value(preround_time)
			bonus_window.hide()
			state_label.text = "Préparation"
		STATE.ROUND:
			input_handler.update_authorisation_to_input(true)
			round_timer.start(round_time)
			time_display.set_max_value(round_time)
			bonus_window.timedisplay.set_max_value(round_time)
			state_label.text = "Manche " + str(round_counter)
		STATE.SHOPPING:
			input_handler.update_authorisation_to_input(false)
			bonus_window.set_pattern(my_domain.spellbook.pattern.get_list())
			bonus_window.show()
			round_timer.start(shopping_time)
			time_display.set_max_value(shopping_time)
			state_label.text = "Interlude"
		STATE.ENDED:
			bonus_window.hide()
			pause_mode_activation(true)
			state_label.text = "Fin de partie"
			
remote func keyboard_action(pid: int, type: int):
	if get_tree().is_network_server():
		for id in network.players:
			if id != 1:
				rpc_id(id, "keyboard_action", pid, type)
				
	#maybe a border slightly glowing ?

remote func changing_stance(gid: int, new_stance):
	if get_tree().is_network_server():
		for id in network.players:
			if id != 1:
				rpc_id(id, "changing_stance", gid, new_stance)
				
	print("new stance for domain " + str(gid) + ": " + str(new_stance))
	var targetted_domain = get_domain_by_gid(gid)
	if targetted_domain:
		targetted_domain.update_stance(new_stance)
	
remote func incantation_progress_changed(game_id, n):
	if get_tree().is_network_server():
		rpc("incantation_progress_changed", game_id, n)
	
	var targetted_domain = get_domain_by_gid(game_id)
	if targetted_domain:
		targetted_domain.incantation_progress_changed(n)
		
remote func defense_power_changed(game_id, x):
	if get_tree().is_network_server():
		rpc("defense_power_changed", game_id, x)
	
	var targetted_domain = get_domain_by_gid(game_id)
	if targetted_domain:
		targetted_domain.update_stat_display(PlayerDomain.STAT.DEFENSE_POWER, x)
		
remote func potential_value_changed(game_id, x):
	if get_tree().is_network_server():
		rpc("potential_value_changed", game_id, x)
		
	var targetted_domain = get_domain_by_gid(game_id)
	if targetted_domain:
		targetted_domain.update_stat_display(PlayerDomain.STAT.DEFENSE_POWER, x)

remote func money_value_changed(gid, n):
	if get_tree().is_network_server():
		rpc("money_value_changed", gid, n)
		
	if gid==game_id:
		bonus_window.set_money_value(n)
		
	var targetted_domain = get_domain_by_gid(game_id)
	if targetted_domain:
		targetted_domain.base_data.spellbook.set_money_value(n)
		
func activate_AI_for_round_time():
	if get_tree().is_network_server():
		for domain in enemy_domains.get_children():
			if domain.is_bot():
				domain.ai_node.determine_ai_time_to_answer()

func pause_AI():
	if get_tree().is_network_server():
		for domain in enemy_domains.get_children():
			if domain.is_bot():
				domain.ai_node.pause_AI()
				
#attack from pid to target_id
func meteor_cast(gid: int, target_game_id: int, threat_data: Dictionary):
	var targetted_domain = get_domain_by_gid(target_game_id)
	if targetted_domain:
		total_meteor_sent+=1
		targetted_domain.add_threat(gid, threat_data, false)
		print("meteor casted")
		
func meteor_impact(gid: int, meteor_id, meteor_hp, power):
	print("GamefieldMulti meteor impact in domain " + str(gid))
	var targetted_domain = get_domain_by_gid(gid) 
	if targetted_domain:
		targetted_domain.threat_impact(meteor_hp, power)
		
func meteor_remove(gid: int, meteor_id: int):
	if get_tree().is_network_server():
		for id in network.players:
			if id != 1:
				rpc_id(id, "meteor_remove", gid, meteor_id)
			#since bots are controlled by server, their meteors
			#destroy themselves
			
	var target_domain = get_domain_by_gid(gid)
	if target_domain:
		target_domain.remove_threat(meteor_id)
	
remote func magic_projectile_cast(gid, target, char_id, start_pos: Vector2, power):
	if get_tree().is_network_server():
		#data must be sent to everyone by the server
		for id in network.players:
			if id != 1:
				rpc_id(id, "magic_projectile_cast", gid, target, char_id, start_pos, power)

	var target_domain = get_domain_by_gid(gid)
	if target_domain:
		target_domain.domain_field.create_magic_homing_projectile(target, char_id, start_pos, power)

#calls result_answer from player identified with gid
remote func check_answer(op, ans, gid):
	#only the server is habilitated to give the answer
	print("check answer for player " + str(gid))
	if get_tree().is_network_server():
		if state == STATE.ROUND:
			var domain = get_domain_by_gid(gid)
			if domain:
				var stat_calcul = [
					op.get_type(),
					op.get_diff(),
					op.get_parameters(),
					domain.base_data.get_answer_time(),
					ans,
					true, #correct answer
				]
				# the result is stored inside the operation for now...
				
				#calling the function in other players instance
				if not op.is_result(ans):
					stat_calcul[5] = false
				#we only call result_answer in server
	#			for id in network.players:
	#				if id != 1:
	#					rpc_id(id, "result_answer", gid, stat_calcul[5])
				#we store it in the list
				game_stats.append(stat_calcul)
				
				#then we call it on ourself
				result_answer(gid, stat_calcul[5])
	
#only used by server to apply modifications on nodes.
#signals are propagated to call rpcs in client nodes if there is
#data to send
remote func result_answer(gid, good_answer: bool):
	if get_tree().is_network_server():
		print("result answer for player " + str(gid) + ": " + str(good_answer))
		emit_signal("domain_answer_response", gid, good_answer)

remote func damage_taken(gid: int, n: int):
	if get_tree().is_network_server():
		for id in network.players:
			if id != 1:
				rpc_id(id, "damage_taken", gid, n)

	var target_domain = get_domain_by_gid(gid)
	if target_domain:
		target_domain.base_data.get_damage(n)

remote func hp_value_changed(gid, hp):
	if get_tree().is_network_server():
		rpc("hp_value_changed", gid, hp)
	
	print("domain " + str(gid) + " has now " + str(hp) + " hp.")
	var domain = get_domain_by_gid(gid)
	if domain:
		domain.update_hp_value(hp)

remote func threat_damage_taken(gid, id_meteor, n):
	if get_tree().is_network_server():
		for id in network.players:
			if id != 1:
				rpc_id(id, "threat_damage_taken", gid, id_meteor, n)
			
	var domain = get_domain_by_gid(gid)
	if domain:
		domain.domain_field.inflict_damage_to_threat(id_meteor, n)

remote func damage_healed(gid: int, n: int):
	if get_tree().is_network_server():
		for id in network.players:
			if id != 1:
				rpc_id(id, "damage_healed", gid, n)
				
	var domain = get_domain_by_gid(gid)
	if domain:
		domain.base_data.heal(n)

remote func update_incantation(gid: int, n: int):
	if get_tree().is_network_server():
		for id in network.players:
			if id != 1:
				rpc_id(id, "update_incantation", gid, n)
			
	var domain = get_domain_by_gid(gid)
	if domain:
		domain.incantation_progress.update_nb_elements_completed(n)

remote func set_waiting_transaction(b: bool):
	my_domain.spellbook.waiting_transaction = b
	 
#this function can probably be optimized
remote func ask_server_for_bonus_action(gid, action_type, L: Array):
	var who = get_tree().get_rpc_sender_id()
	if get_tree().is_network_server():
		print("All domains GID:")
		print(str(get_array_of_all_domains()))
		var domain = get_domain_by_gid(gid)
		print("domain: " + str(domain))
		print("Player " + str(gid) + " wants to do shop action " + str(action_type))
		if domain:
			var already_buying = domain.is_waiting_for_transaction_end()
			if already_buying:
				rpc_id(who, "server_answer_for_bonus_action", false, Spellbook.BUYING_OP_ATTEMPT_RESULT.ALREADY_BUYING, [])
				return
			domain.update_transaction_status(true)
			
			#checking if the action is possible according to 
			#the data in the server
			var buy_status = check_shop_operation(gid, action_type, L[0])

			#then we apply modifications on the server
			if buy_status == Spellbook.BUYING_OP_ATTEMPT_RESULT.CAN_BUY:
				match(action_type):
					BonusMenuBis.BONUS_ACTION.BUY_OPERATION:
						domain.shop_action(action_type, L[0].get_price(), L[0])
					BonusMenuBis.BONUS_ACTION.ERASE_OPERATION:
						domain.shop_action(action_type, L[0].get_price(), L[0])
					BonusMenuBis.BONUS_ACTION.SWAP_OPERATIONS:
						pass

			#if the one asking is not a bot
			if who != 1:
				rpc_id(who, "server_answer_for_bonus_action", buy_status, action_type, L)
			else:
				server_answer_for_bonus_action(buy_status, action_type, L)
			
			domain.update_transaction_status(false)
		else:
			#Error case
			if get_tree().is_network_server():
				server_answer_for_bonus_action(Spellbook.BUYING_OP_ATTEMPT_RESULT.ERROR, false, [])
			else:
				rpc_id(gid, "server_answer_for_bonus_action", Spellbook.BUYING_OP_ATTEMPT_RESULT.ERROR, false, [])

remote func server_answer_for_bonus_action(answer_type, action_type, L):
	var display_time = 3.0
	var message = ""
	var pos = 1
	print("server answer: " + str(answer_type))
	match(answer_type):
		Spellbook.BUYING_OP_ATTEMPT_RESULT.CAN_BUY:
			message = "Achat effectué !"
			match(action_type):
				BonusMenuBis.BONUS_ACTION.BUY_OPERATION:
					my_domain.shop_action(action_type, L[0].get_price(), L[0])
				BonusMenuBis.BONUS_ACTION.ERASE_OPERATION:
					my_domain.shop_action(action_type, L[0].get_price(), L[0])
				BonusMenuBis.BONUS_ACTION.SWAP_OPERATIONS:
					pass
			bonus_window.set_pattern(my_domain.spellbook.pattern.get_list())
		Spellbook.BUYING_OP_ATTEMPT_RESULT.NO_MONEY:
			message = "Pas assez d'argent, économisez !"
		Spellbook.BUYING_OP_ATTEMPT_RESULT.NO_SPACE:
			message = "Vous ne pouvez pas compléter davantage votre Incantation !"
		Spellbook.BUYING_OP_ATTEMPT_RESULT.ERROR:
			message = "Une erreur est survenue lors de l'achat..."

	create_pop_up_notification(display_time, message,pos)
	
#the server updates all data in the domains, which will
#send signals, which will call rpcs to send data
#to the client
#TO BE CONTINUED
func new_round():
	if get_tree().is_network_server():
		round_counter += 1
		for domain in get_array_of_all_domains():
			if domain != my_domain:
				domain.base_data.spellbook.new_round()
	
	my_domain.base_data.spellbook.new_round()
	
remote func restart_timer(t: float):
	if get_tree().is_network_server():
		for id in network.players:
			if id != 1:
				rpc_id(id, "restart_timer", t)
				
	round_timer.start(t)

remote func pause_mode_activation(b: bool):
	if get_tree().is_network_server():
		for id in network.players:
			if id != 1:
				rpc_id(id, "pause_mode_activation", b)
				
	get_tree().paused = b

#only the server can generate the new operations 
#for each player.
func generate_all_shop_operations():
	if get_tree().is_network_server():

		#dict of all new operations from all players
		#keys are game_ids
		var all_players_game_id = []
		var new_op_dict = {}
		var all_domains_array = get_array_of_all_domains()
		#we first generate all new operations from all players
		#(bots included)
		for domain in all_domains_array:
			var id = domain.game_id
			all_players_game_id.append(id)
			if domain:
				var operation_preference = domain.spellbook.get_operation_preference()
				var difficulty_preference = domain.spellbook.get_difficulty_preference()
				var n = domain.spellbook.get_operation_production()
				print("Player " + str(id) + ": " + str(n) + " new operations")
				new_op_dict[id] = []
				for i in range(n):
					var type = ponderate_random_choice_dict(operation_preference)
					var diff = ponderate_random_choice_dict(difficulty_preference)
					var new_op_data = [type,diff] 
					print("new operation element added : " + str(new_op_data))
					new_op_dict[id].append(new_op_data)
					
		#the player have also access to a part of operations
		#from the enemies. Now we can do it.
		var new_op_enemies_dict = {}
		
		var all_players_game_id_except_one
		for domain in all_domains_array:
			var gid = domain.game_id
			all_players_game_id_except_one = all_players_game_id.duplicate()
			all_players_game_id_except_one.erase(gid)
			#dict of new operations that will be given to the player
			#considered
			new_op_enemies_dict[gid] = []
			#we should create the list of all players
			#except the one considered here.

			var n = domain.spellbook.get_inspiration()
			for i in range(n):
				#each time, we choose a random op
				# from a random player
				var player_tirage = all_players_game_id_except_one[randi() % all_players_game_id_except_one.size()]
				var operation = new_op_dict[player_tirage][randi()% new_op_dict[player_tirage].size()]
				var type = operation[0]
				var diff = operation[1]
				new_op_enemies_dict[gid].append([type,diff, player_tirage])
		
			#now we can send the data to the player
			#only if the domain is not one of a bot !
			if not domain.is_bot():
				if gid == 1:
					send_shop_operations(new_op_dict[gid], new_op_enemies_dict[gid])
				else:
					#send with the PID and not the GID
					rpc_id(domain.player_id, "send_shop_operations", new_op_dict[gid], new_op_enemies_dict[gid])
			#and update server's data
			
			
remote func send_shop_operations(new_op_player: Array, new_op_others: Array):
	bonus_window.set_new_operations(new_op_player, new_op_others)
	
func apply_shop_transaction(gid, action_type, L):
	var domain = get_domain_by_pid(gid)
	if domain:
		domain.shop_action(action_type, L[0].get_price(), L[0])

#TO BE CONTINUED
remote func defeated():
	pass
	
remote func end_of_game():
	pass
	
#returns a value explaining if the pid player can buy
#the thing he asks.
func check_shop_operation(gid: int, action_type, element):
	if get_tree().is_network_server():
		var domain = get_domain_by_gid(gid)
		if domain:
			var money = domain.get_money()
			var cost
			match(action_type):
				BonusMenuBis.BONUS_ACTION.BUY_OPERATION:
					#if the user wants to buy an operation, then
					#the element given is an instance of Operation_Display
					var op_name = element.get_name()
					cost = element.get_price()
				BonusMenuBis.BONUS_ACTION.ERASE_OPERATION:
					cost = domain.base_data.get_erase_price()
				BonusMenuBis.BONUS_ACTION.SWAP_OPERATIONS:
					cost = domain.base_data.get_swap_price()

			#note: buy_attempt_result only considers Operation buying
			#so it checks if we can add one.
			var buy_status = domain.spellbook.buy_attempt_result(action_type, cost)
			return buy_status

remote func get_new_incantation_operations(L: Array):
	my_domain.base_data.spellbook.store_new_incantations(L)
	print("player " + str(game_id) + " got " + str(len(L))+ " new incantations")
	
#the players rpc this function and the server determines the target
#or the target is given by the player
#TO BE CONTINUED
remote func player_meteor_incantation(gid, dico_threat):
	var who = get_tree().get_rpc_sender_id()
	print("Meteor incantation from player " + str(gid))
	if get_tree().is_network_server():
		#for now, random target...
		var target = operation_factory.choice(get_all_targetable_players(gid))
		print("Player " + str(gid) + " targets " + str(target))
		rpc("meteor_cast", gid, target, dico_threat)
		meteor_cast(gid, target, dico_threat)

#TO BE CONTINUED
remote func player_defense_command(gid, power):
	if get_tree().is_network_server():
		rpc("player_defense_command", gid, power)
		
	var domain = get_domain_by_pid(gid)
	if domain:
		domain.domain_field.magic_projectile_incantation(power)
	
func determine_target(dico_threat):
	pass
	
#generate n full patterns of operations for the player gid.
remote func generate_new_incantation_operations(gid: int, n = 2):
	if get_tree().is_network_server():
		print("operations generation for player " + str(gid))
		var domain = get_domain_by_gid(gid)
		if domain:
			var pid = domain.player_id
			var array_of_full_operation_list = []
			var pattern = domain.base_data.spellbook.pattern.get_list()
			var new_operation_list = []
			var new_operation
			for i in range(n):
				new_operation_list.clear()
				for p_element in pattern:
					new_operation = operation_factory.generate(p_element)
					new_operation_list.append(new_operation)
				array_of_full_operation_list.append(new_operation_list)
				
			if domain.is_bot() or domain == my_domain:
				domain.base_data.spellbook.store_new_incantations(array_of_full_operation_list)
				print("incantations generated for player " + str(gid))
			else:
				rpc_id(pid, "get_new_incantation_operations", array_of_full_operation_list)
			
func get_all_targetable_players(gid: int) -> Array:
	var targets = []
	var iterated_domain_gid
	for domain in get_array_of_all_domains():
		iterated_domain_gid = domain.get_gid()
		if not domain.is_eliminated() and iterated_domain_gid != gid:
			targets.append(iterated_domain_gid)
	return targets
	
func ponderate_random_choice_dict(dict: Dictionary):
	#Returns a random key from dict.
	#Evaluate first the sum S of all values and generate
	#then a random number x to determine the key picked.
	var S = 0
	for v in dict.values():
		S += v
	var r = rng.randf()*S
	var total = 0
	
	var list = dict.keys()
	var i = 0
	var n = len(list)
	while i < n and total <= r:
		total += dict[list[i]]
		i+=1
	return list[i-1]
	

func get_domain_by_pid(pid: int):
	if pid == my_domain.player_id:
		return my_domain
		
	var node_name
	if pid in network.players:
		node_name = str(pid)
	elif pid in network.bots:
		node_name = "bot_"+str(pid)
		
	var domain = enemy_domains.get_node(node_name)
	if domain:
		return domain
		
	return null
	
func get_domain_by_gid(gid: int):
	if gid == game_id:
		return my_domain

	for domain in enemy_domains.get_children():
		if domain.get_gid() == gid:
			return domain
			
	return null
	
func get_gid():
	return game_id
	
func get_array_of_all_domains() -> Array:
	var array = []
	array.append(my_domain)
	array.append_array(enemy_domains.get_children())
	return array
	
func is_waiting_for_transaction_end():
	return my_domain.spellbook.get_waiting_transaction()
	
func create_pop_up_notification(display_time: float, message: String, pos = 1):
	var popup = POPUPCLASS.instance()
	popup_nodes.add_child(popup)
	popup.initialize(display_time, message, pos)
	popup.change_position(Vector2(500, 600))
	popup.display_on_screen()
	
func _on_GameFieldMulti_ready():
	if get_tree().is_network_server():
		client_ready(1)
	else:
		rpc_id(1, "client_ready", game_id)

func _on_player_list_changed():
	# First remove all children from the boxList widget
	for c in enemy_domains.get_children():
		c.queue_free()
	
	# Now iterate through the player list creating a new entry into the boxList
	for p in network.players:
		if (p != Gamestate.player_info["net_id"]):
			var nlabel = Label.new()
			nlabel.text = network.players[p]["pseudo"]
			enemy_domains.add_child(nlabel)

func _on_round_time_remaining_timeout():
	if get_tree().is_network_server():
		var next_state
		print("current state: " + str(state))
		match(state):
			1:
				#the game stops if not everyone is ready after
				#the delay
				next_state = STATE.ENDED
			2:
				next_state = STATE.ROUND
			3:
				next_state = STATE.SHOPPING
			4:
				next_state = STATE.PREROUND
		print(next_state)
		rpc("changing_state", next_state)

func _on_bonus_menu_player_asks_for_action(game_id, action_type, element):
	var money = my_domain.base_data.get_money()
	var cost
	match(action_type):
		BonusMenuBis.BONUS_ACTION.BUY_OPERATION:
			#if the user wants to buy an operation, then
			#the element given is an instance of Operation_Display
			var op_name = element.get_name()
			cost = element.get_price()
		BonusMenuBis.BONUS_ACTION.ERASE_OPERATION:
			cost = my_domain.base_data.get_erase_price()
		BonusMenuBis.BONUS_ACTION.SWAP_OPERATIONS:
			cost = my_domain.base_data.get_swap_price()
			
	#we can make the client check first if he can buy
	#the server will check it anyway
	#note: buy_attempt_result only considers Operation buying
	#so it checks if we can add one.
	var buy_status = my_domain.spellbook.buy_attempt_result(action_type, cost)
	var display_time = 3.0
	var message = ""
	var pos = 1
	match(buy_status):
		Spellbook.BUYING_OP_ATTEMPT_RESULT.CAN_BUY:
			pass
		Spellbook.BUYING_OP_ATTEMPT_RESULT.NO_MONEY:
			message = "Pas assez d'argent, économisez!"
		Spellbook.BUYING_OP_ATTEMPT_RESULT.NO_SPACE:
			message = "Vous ne pouvez pas compléter davantage votre Incantation !"
		Spellbook.BUYING_OP_ATTEMPT_RESULT.ERROR:
			message = "Erreur lors de l'achat"
	
	var can_buy = buy_status == Spellbook.BUYING_OP_ATTEMPT_RESULT.CAN_BUY
	if can_buy:
		#expecting more action from the user
		match(action_type):
			BonusMenuBis.BONUS_ACTION.SWAP_OPERATIONS:
				bonus_window.change_state(BonusMenu.STATE.SELECTING)

			BonusMenuBis.BONUS_ACTION.BUY_OPERATION:
				if not get_tree().is_network_server():
					rpc_id(1, "ask_server_for bonus_action", game_id, action_type, [element])
				else:
					ask_server_for_bonus_action(game_id, action_type, [element])
	else:
		create_pop_up_notification(display_time, message,pos)
		
func _on_enemy_elimination(pid: int):
	pass

func _on_InputHandler_keyboard_action(action):
	pass
	
func _on_InputHandler_check_answer_command():
	print("checking answer command")
	var op = my_domain.spellbook.get_current_operation()
	var ans = operation_display.get_answer()
	var pid = Gamestate.player_info["net_id"]
	if get_tree().is_network_server():
		check_answer(op, ans, pid)
	else:
		rpc_id(1, "check_answer", op, ans, pid)

#if we press buttons, we might send the information to the server but it's useless
func _on_InputHandler_delete_digit():
	if get_tree().is_network_server():
		keyboard_action(1, 1)
	else:
		rpc_id(1, "keyboard_action", Gamestate.player_info["net_id"], 1)


func _on_InputHandler_write_digit(d):
	if get_tree().is_network_server():
		keyboard_action(1, 2)
	else:
		rpc_id(1, "keyboard_action", Gamestate.player_info["net_id"], 2)


func _on_bonus_menu_operations_selection_done(L, state):
	var action_type
	match(state):
		STATE.IDLE:
			pass
		STATE.REPLACING_OP:
			pass
		STATE.SWAPPING:
			action_type = BonusMenuBis.BONUS_ACTION.SWAP_OPERATIONS
		STATE.SELECTING:
			action_type = BonusMenuBis.BONUS_ACTION.ERASE_OPERATION
			
	if Gamestate.player_info["net_id"] != 1:
		rpc_id(1, "ask_server_for bonus_action", game_id, action_type, L)
	else:
		ask_server_for_bonus_action(game_id, action_type, L)

func _on_spellbook_meteor_invocation(game_id, dico_threat):
	print("Meteor invocation !")
	if get_tree().is_network_server():
		player_meteor_incantation(game_id, dico_threat)
	else:
		rpc_id(1, "player_meteor_incantation", dico_threat)
		
func _on_spellbook_defense_command(game_id, power):
	print("Defense command from player " + str(game_id))
	if get_tree().is_network_server():
		player_defense_command(game_id, power)
	else:
		rpc_id(1, "player_defense_command", game_id, power)

func _on_spellbook_low_incantations_stock(game_id):
	if get_tree().is_network_server():
		generate_new_incantation_operations(Gamestate.player_info["net_id"], 2)
	else:
		rpc_id(1, "generate_new_incantation_operations", Gamestate.player_info["net_id"], 2)


func _on_spellbook_incantation_has_changed(gid, L):
	var domain = get_domain_by_gid(gid)
	if domain:
		domain.incantation_has_changed(L)
	
	#on the server side, if it is not a bot
	if gid == game_id:
		#update incantation in bonus_menu
		bonus_window.set_pattern(L)
		
func _on_spellbook_operation_to_display_has_changed(gid, new_op):
	if gid == game_id:
		operation_display.change_operation_display(new_op)
		
func _on_spellbook_incantation_progress_changed(game_id, n):
	if get_tree().is_network_server():
		incantation_progress_changed(game_id, n)
	else:
		rpc_id(1, "incantation_progress_changed", game_id, n)
	
func _on_spellbook_potential_value_changed(game_id, x):
	if get_tree().is_network_server():
		potential_value_changed(game_id, x)
	else:
		rpc_id(1, "potential_value_changed", game_id, x)
	
func _on_spellbook_defense_power_changed(game_id, x):
	if get_tree().is_network_server():
		defense_power_changed(game_id, x)
	else:
		rpc_id(1, "defense_power_changed", game_id, x)
	
func _on_spellbook_money_value_has_changed(gid, money):
	if get_tree().is_network_server():
		money_value_changed(gid, money)
		
func _on_domain_field_meteor_destroyed(gid, meteor_id):
	if get_tree().is_network_server():
		meteor_remove(gid, meteor_id)

func _on_domain_field_meteor_hp_changed(gid, meteor_id, hp):
	if get_tree().is_network_server():
		threat_damage_taken(gid, meteor_id, hp)

func _on_domain_field_meteor_impact(gid, meteor_id, meteor_hp, power):
	if get_tree().is_network_server():
		meteor_impact(gid, meteor_id, meteor_hp, power)

func _on_magic_projectile_end_with_power_left(gid, power, type):
	var effective_power = power
	var domain = get_domain_by_gid(gid)
	var dico_threat
	if domain:
		dico_threat = domain.base_data.spellbook.generate_threat_data_dict()
		print("Meteor invocation !")
		if get_tree().is_network_server():
			player_meteor_incantation(game_id, dico_threat)
		else:
			rpc_id(1, "player_meteor_incantation", dico_threat)

		
func _on_base_data_hp_value_changed(gid, hp):
	if get_tree().is_network_server():
		hp_value_changed(gid, hp)
	else:
		rpc_id(1, "hp_value_changed", gid, hp)
#tests
func _on_receive_meteor_pressed():
	if get_tree().is_network_server():
		pass


func _on_remove10sec_button_button_down():
	round_timer.start(clamp(round_timer.time_left - 10, 0, 100))


func _on_InputHandler_input_stance_change(new_stance):
	print("changing stance command: " + str(new_stance))
	if get_tree().is_network_server():
		changing_stance(1, new_stance)
	else:
		rpc_id(1, "changing_stance",game_id, new_stance)
