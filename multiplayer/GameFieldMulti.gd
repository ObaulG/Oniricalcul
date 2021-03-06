extends Node2D

var POPUPCLASS = load("res://UI/PopUpNotification.tscn")
var pclass = load("res://multiplayer/BaseDomainDisplay.tscn")
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
signal new_incantations_received(L)
signal game_state_changed(new_state)
signal changing_stance_command(new_stance)

#to avoid conflict between client ids and bot ids
var game_id: int
var clients_ready_to_play = []
var rng = RandomNumberGenerator.new()
var round_counter: int
var operation_factory: OperationFactory

var game_type

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

#only for server: stores all the shop elements
var all_shop_elements = {}
#stored by the server. keys and values are pids
var targets: Dictionary

var game_data: Dictionary

var base_data

var total_meteor_sent:= 0

onready var incantation_factory = $IncantationFactory
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
	bonus_window.game_id = game_id
	print("my game_id: " + str(game_id))
	# Connect event handler to the player_list_changed signal
	network.connect("player_list_changed", self, "_on_player_list_changed")

	#or stop the game if we are disconnected
	get_tree().connect("server_disconnected", self, "_on_disconnected_from_server")
	
	# Must act if disconnected from the server
	network.connect("disconnected", self, "_on_disconnected")
	
	network.connect("player_removed", self, "_on_player_removed")
	operation_factory = OperationFactory.new()

	state = STATE.WAITING_EVERYONE
	ready_label.text = "Joueurs pr??ts: 0 / " + str(len(clients_ready_to_play))
	
	round_time = ROUND_TIME
	preround_time = PREROUND_TIME
	shopping_time = SHOPPING_TIME

	my_domain.initialise(network.players[Gamestate.player_info["net_id"]])
	
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
	my_domain.base_data.connect("eliminated", self, "_on_player_eliminated")
	my_domain.domain_field.connect("meteor_destroyed", self, "_on_domain_field_meteor_destroyed")
	my_domain.domain_field.connect("meteor_impact", self, "_on_domain_field_meteor_impact")
	my_domain.domain_field.connect("meteor_hp_changed", self, "_on_domain_field_meteor_hp_changed")
	my_domain.domain_field.connect("magic_projectile_end_with_power_left", self, "_on_magic_projectile_end_with_power_left")
	
	#everyone has already the data to spawn every single player in network singleton
	spawn_players()
	print("all players have been initialised")
	
	targets = {}
	time_display.set_min_value(0)
	time_display.set_max_value(60)
	round_timer.start(60)

	if get_tree().is_network_server():
		print("Init generation of incantations")
		generate_new_incantation_operations(my_domain.game_id, 3)
	else:
		rpc_id(1,"generate_new_incantation_operations", my_domain.game_id, 3)

	bonus_window.game_id = game_id
	
	if get_tree().is_network_server():
		game_data = {
		"timestamp_start": 0,
		"timestamp_end": 0,
		"players_dict": {}, #{game_id : pseudo}
		"game_actions": [],
		"eliminations": []
		}
		#TODO
		for id in network.players:
			var gid = network.players[id]["game_id"]
			var pseudo = network.players[id]["pseudo"]
			game_data["players_dict"][gid] = pseudo
		client_ready(game_id)
	print("XD -----------------------------------------------------------")
func _process(delta):
	if not pause_mode:
		game_time += delta
	time_display.set_new_value(round_timer.time_left)
	bonus_window.set_time(round_timer.time_left)
	
func _on_player_removed(pinfo: Dictionary):
	if get_tree().is_network_server():
		player_eliminated(pinfo["game_id"])

func _on_disconnected_from_server():
	leave_game()

func leave_game():
	if get_tree().is_network_server():
		network.end_connection()
	scene_transition_rect.change_scene("res://scenes/titlescreen/title.tscn")
	
func spawn_players():
	for id in network.players:
		if id != Gamestate.player_info["net_id"]:
			generate_actor(network.players[id])

	for id in network.bots:
		generate_actor(network.bots[id])
		
	print("All actors generated !")
	
#called to tell everyone the game is about to start
remote func client_ready(gid: int):
	if not (gid in clients_ready_to_play):
		print("Client " + str(gid) + " ready!")
		clients_ready_to_play.append(gid)
		ready_label.text = "Joueurs pr??ts: " + str(len(clients_ready_to_play)) +" / " + str(network.get_total_players_entities())
		if get_tree().is_network_server():
			rpc("client_ready", gid)
					
			#might cause problems ?
			if len(clients_ready_to_play) >= network.get_total_players_entities():
				print("GAME STARTING")
				rpc("game_about_to_start")


#note: meteor and projectile casts are only visual in clients: if it is display
#on a basedomaindisplay, then it's not the main character so they should
#not send data from other players.
#used to generate other players instances (BaseDomainDisplay)
func generate_actor(pinfo):
	# Load the scene and create an instance
	var nactor = pclass.instance()
	
	# add the actor into the world
	enemy_domains.add_child(nactor)
	# domain initialization
	nactor.initialise(pinfo)
	nactor.set_name(str(pinfo["net_id"]))
	
	if get_tree().is_network_server():
		#bot initialisation
		if pinfo["is_bot"]:
			bot_game_data[pinfo["game_id"]] = {}
			bot_game_data[pinfo["game_id"]]["shop_operations"] = []
			nactor.set_name("bot_"+str(pinfo["net_id"]))
			var bot_diff = pinfo["bot_diff"]
			nactor.ai_node.set_hardness(bot_diff)
			nactor.activate_AI()
		else:
			# If this actor does not belong to the server, change the node name and network master accordingly
			if (pinfo["net_id"] != 1):
				nactor.set_network_master(pinfo["net_id"])
		
		print("nactor incantation generation")
		generate_new_incantation_operations(pinfo["game_id"], 3)
		
		nactor.base_data.spellbook.connect("meteor_invocation", self, "_on_spellbook_meteor_invocation")
		nactor.base_data.spellbook.connect("defense_command", self, "_on_spellbook_defense_command")
		nactor.base_data.spellbook.connect("low_incantation_stock", self, "_on_spellbook_low_incantations_stock")
		nactor.base_data.spellbook.connect("incantation_has_changed", self, "_on_spellbook_incantation_has_changed")
		nactor.base_data.spellbook.connect("potential_value_changed", self, "_on_spellbook_potential_value_changed")
		nactor.base_data.spellbook.connect("defense_power_changed", self, "_on_spellbook_defense_power_changed")
		nactor.base_data.spellbook.connect("money_value_has_changed", self, "_on_spellbook_money_value_has_changed")
		
		nactor.base_data.connect("hp_value_changed", self, "_on_base_data_hp_value_changed")
		nactor.domain_field.connect("meteor_destroyed", self, "_on_domain_field_meteor_destroyed")
		nactor.domain_field.connect("meteor_impact", self, "_on_domain_field_meteor_impact")
		nactor.domain_field.connect("meteor_hp_changed", self, "_on_domain_field_meteor_hp_changed")
		nactor.domain_field.connect("magic_projectile_end_with_power_left", self, "_on_magic_projectile_end_with_power_left")
		nactor.base_data.spellbook.connect("money_value_has_changed", bonus_window, "_on_spellbook_money_value_has_changed")
		
		#send signal to tell everyone this bot is ready
		client_ready(pinfo["game_id"])
		
	#we add connections (elimination, meteor casts, projectile casts, etc)
	#this signal is call on the client (not processed by server)
	nactor.base_data.connect("eliminated", self, "_on_enemy_elimination")
	
#called to tell all clients the game can start
remotesync func game_about_to_start():
	print("---------------------------------------")
	print("GAME STARTING")
	pause_mode = false
	changing_state(STATE.PREROUND)
	
	#showing 1st operation
	my_domain.base_data.spellbook.charge_new_incantation()

	var operation_to_display = my_domain.base_data.spellbook.get_current_operation()
	print("operation: " + str(operation_to_display))
	operation_display.change_operation_display(operation_to_display)
	my_domain.update_all_stats_display()
	
	for domain in enemy_domains.get_children():
		if domain.is_bot():
			domain.base_data.spellbook.charge_new_incantation()
			domain.update_all_stats_display()
			
	if get_tree().is_network_server():
		for domain in get_array_of_all_domains():
			var gid = domain.game_id
			all_shop_elements[gid] = {"new_operations": []}
#we are not supposed to jump states, but just in case,
#we give the new state as an argument
remotesync func changing_state(new_state):
	round_timer.stop()
	if get_tree().is_network_server():
		match(new_state):
			STATE.PREROUND:
				new_round()
				bonus_window.end_selection()
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
			input_handler.update_authorisation_to_input(false)
			round_timer.start(preround_time)
			time_display.set_max_value(preround_time)
			bonus_window.hide()
			state_label.text = "Pr??paration"
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
			input_handler.update_authorisation_to_input(false)
			bonus_window.hide()
			round_timer.stop()
			state_label.text = "Fin de partie"
			if not my_domain.is_eliminated():
				stop_playing(true)

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
	
remote func incantation_progress_changed(gid, n):
	if get_tree().is_network_server():
		rpc("incantation_progress_changed", gid, n)
	
	var targetted_domain = get_domain_by_gid(gid)
	if targetted_domain:
		targetted_domain.incantation_progress_changed(n)
		
remote func defense_power_changed(gid, x):
	if get_tree().is_network_server():
		rpc("defense_power_changed", gid, x)
	
	var targetted_domain = get_domain_by_gid(gid)
	if targetted_domain:
		targetted_domain.update_stat_display(PlayerDomain.STAT.DEFENSE_POWER, x)
		
remote func potential_value_changed(gid, x):
	if get_tree().is_network_server():
		rpc("potential_value_changed", gid, x)
		
	var targetted_domain = get_domain_by_gid(gid)
	if targetted_domain:
		targetted_domain.update_stat_display(PlayerDomain.STAT.DEFENSE_POWER, x)

remote func money_value_changed(gid, n):
	if get_tree().is_network_server():
		rpc("money_value_changed", gid, n)
		
	print("domain " + str(gid) + " new money: " + str(n))
	if gid == game_id:
		bonus_window.set_money_value(n)
		
	var targetted_domain = get_domain_by_gid(gid)
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
remote func meteor_cast(gid: int, target_game_id: int, threat_data: Dictionary):
	if get_tree().is_network_server():
		rpc("meteor_cast", gid, target_game_id, threat_data)
		
	var targetted_domain = get_domain_by_gid(target_game_id)
	if targetted_domain:
		total_meteor_sent+=1
		targetted_domain.add_threat(gid, threat_data, false)
		print("meteor casted")
		
remote func meteor_impact(gid: int, meteor_id, meteor_hp, power):
	if get_tree().is_network_server():
		rpc("meteor_impact", gid, meteor_id, meteor_hp, power)
	
	if state != STATE.ENDED:
		print("GamefieldMulti meteor impact in domain " + str(gid))
		var targetted_domain = get_domain_by_gid(gid) 
		if targetted_domain:
			targetted_domain.threat_impact(meteor_hp, power)
		
remote func meteor_remove(gid: int, meteor_id: int):
	if get_tree().is_network_server():
		rpc("meteor_remove", gid, meteor_id)
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
remote func check_answer(ans, gid):
	#only the server is habilitated to give the answer
	print("check answer for player " + str(gid))
	if get_tree().is_network_server():
		if state == STATE.ROUND:
			var domain = get_domain_by_gid(gid)
			if domain:
				var op = domain.base_data.spellbook.get_current_operation()
				var stat_calcul = [
					gid,
					op.get_type(),
					op.get_diff(),
					op.get_operands(),
					domain.base_data.get_answer_time(),
					ans,
					true, #correct answer
				]
				# the result is stored inside the operation for now...
				
				if not op.is_result(ans):
					stat_calcul[6] = false
				
				print("answer: " + str(stat_calcul[6]))
				#we store it in the list
				game_data["game_actions"].append(stat_calcul)
				#will send data to everyone
				result_answer(gid, stat_calcul[6])
	
#only used by server to apply modifications on nodes.
#signals are propagated to call rpcs in client nodes if there is
#data to send
remote func result_answer(gid, good_answer: bool):
	if get_tree().is_network_server():
		rpc("result_answer", gid, good_answer)
		print("result answer for player " + str(gid) + ": " + str(good_answer))
		
	print("i have got the answer " + str(good_answer) + " for domain " + str(gid))
	var domain = get_domain_by_gid(gid)
	if domain:
		var is_my_domain = gid == game_id
		print("is this my domain: " + str(is_my_domain))
		domain.answer_action(good_answer, is_my_domain)

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
	 
#this function can probably be optimized.
#L is an array of indexes
remote func ask_server_for_bonus_action(gid, action_type, L: Array):
	var who = get_tree().get_rpc_sender_id()
	if get_tree().is_network_server():
		var domain = get_domain_by_gid(gid)
		print("------------------------------------------------------------")
		print("Player " + str(gid) + " wants to do shop action " + str(action_type))
		if domain:
			var already_buying = domain.is_waiting_for_transaction_end()
			if already_buying:
				rpc_id(who, "server_answer_for_bonus_action", false, Spellbook.BUYING_OP_ATTEMPT_RESULT.ALREADY_BUYING, [])
				return
			domain.update_transaction_status(true)
			
			#checking if the action is possible according to 
			#the data in the server
			#TODO
			var buy_status = check_shop_operation(gid, action_type, L)
			print(buy_status)
			var price: int = -1
			var shop_element = null
			#then we apply modifications on the server
			if buy_status == Spellbook.BUYING_OP_ATTEMPT_RESULT.CAN_BUY:
				print("Granted")
				match(action_type):
					BonusMenuBis.BONUS_ACTION.BUY_OPERATION:
						var i = L[0]
						#[type, diff, price]
						shop_element = all_shop_elements[gid]["new_operations"][i]
						price = shop_element[2]
					BonusMenuBis.BONUS_ACTION.ERASE_OPERATION:
						price = domain.base_data.spellbook.get_erase_price()
					BonusMenuBis.BONUS_ACTION.SWAP_OPERATIONS:
						price = domain.base_data.spellbook.get_swap_price()
					
				if gid != 1:
					if shop_element:
						domain.shop_action(action_type, price, [[shop_element[0], shop_element[1]]])
					else:
						domain.shop_action(action_type, price, L)
					
			#if the one asking is a player but not the server
			if (not domain.is_bot()) and gid != 1:
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

#L is a list of indexes (for buying: index in bonus menu new operations,
#						 for swapping/erasing: index in incantation)
remote func server_answer_for_bonus_action(answer_type, action_type, L):
	var display_time = 3.0
	var message = ""
	var pos = 1
	print("server answer: " + str(answer_type))
	print(L)
	match(answer_type):
		Spellbook.BUYING_OP_ATTEMPT_RESULT.CAN_BUY:
			message = "Achat effectu?? !"
			match(action_type):
				BonusMenuBis.BONUS_ACTION.BUY_OPERATION:
					var op = bonus_window.get_new_operation_by_index(L[0])
					my_domain.shop_action(action_type, op.get_price(), [op.get_pattern_element()])
				BonusMenuBis.BONUS_ACTION.ERASE_OPERATION:
					my_domain.shop_action(action_type, my_domain.base_data.spellbook.get_erase_price(), L)
				BonusMenuBis.BONUS_ACTION.SWAP_OPERATIONS:
					my_domain.shop_action(action_type, my_domain.base_data.spellbook.get_swap_price(), L)
			bonus_window.set_pattern(my_domain.spellbook.pattern.get_list())
			
		Spellbook.BUYING_OP_ATTEMPT_RESULT.NO_MONEY:
			message = "Pas assez d'argent, ??conomisez !"
		Spellbook.BUYING_OP_ATTEMPT_RESULT.NO_SPACE:
			message = "Vous ne pouvez pas compl??ter davantage votre Incantation !"
		Spellbook.BUYING_OP_ATTEMPT_RESULT.ERROR:
			message = "Une erreur est survenue lors de l'achat..."

	create_pop_up_notification(display_time, message,pos)
	
#the server updates all data in the domains, which will
#send signals, which will call rpcs to send data to the client
#TO BE CONTINUED !!
func new_round():
	if get_tree().is_network_server():
		for domain in get_array_of_all_domains():
			domain.base_data.spellbook.new_round()
			if not domain.base_data.spellbook.operation_charged:
				printerr("Server: must generate incantations for " + str(domain.game_id))
				generate_new_incantation_operations(domain.game_id, 3)
	round_counter += 1
	
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
			all_shop_elements[id]["new_operations"] = []
			if domain:
				var operation_preference = domain.spellbook.get_operation_preference()
				var difficulty_preference = domain.spellbook.get_difficulty_preference()
				var n = domain.spellbook.get_operation_production()
				print("Player " + str(id) + ": " + str(n) + " new operations")
				new_op_dict[id] = []
				for i in range(n):
					var type = ponderate_random_choice_dict(operation_preference)
					var diff = ponderate_random_choice_dict(difficulty_preference)
					var price = 5 + pow(2, diff)
					var new_op_data = [type,diff, price] 
					#print("new operation element added : " + str(new_op_data))
					new_op_dict[id].append(new_op_data)
					#we save the data in the server
					all_shop_elements[id]["new_operations"].append(new_op_data)
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
				var price = 5 + pow(2, diff)
				new_op_enemies_dict[gid].append([type,diff, price])
		
				#we save the data in the server
				all_shop_elements[gid]["new_operations"].append([type,diff, price])
			
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

#called when the player's hp fall to 0
#the player must see his end menu and also can also while the game is still playing
#this function is call by the client's base_data (it receives hp loss)
func _on_player_eliminated(gid: int):
	player_eliminated(gid)
	if gid == game_id:
		stop_playing(false)


remote func stop_playing(victory: bool):
	if victory:
		$end_game_window/Panel/game_result_label.text = "Victoire !"
	else:
		$end_game_window/Panel/game_result_label.text = "D??faite..."
	$end_game_window/Panel.show()


#TODO
#stops the game for everyone and show the end menu if not already done
func end_of_game():
	if get_tree().is_network_server():
		rpc("changing_state", STATE.ENDED)
		
		# network.send_game_data_to_server(game_data)

#returns a value explaining if the pid player can buy
#the thing he asks.
func check_shop_operation(gid: int, action_type, L):
	if get_tree().is_network_server():
		var domain = get_domain_by_gid(gid)
		if domain:
			var money = domain.get_money()
			var cost = -1		#-1 --> error

			match(action_type):
				BonusMenuBis.BONUS_ACTION.BUY_OPERATION:
					#if the user wants to buy an operation, then
					#the element given is an instance of Operation_Display
					var i = L[0]
					cost = all_shop_elements[gid]["new_operations"][i][2]
				BonusMenuBis.BONUS_ACTION.ERASE_OPERATION:
					cost = domain.base_data.get_erase_price()
				BonusMenuBis.BONUS_ACTION.SWAP_OPERATIONS:
					cost = domain.base_data.get_swap_price()

			#note: buy_attempt_result only considers Operation buying
			#so it checks if we can add one.
			var buy_status = domain.spellbook.buy_attempt_result(action_type, cost)
			return buy_status

#should not be called from the server.
#list of list of dictionnary representing the operation
remote func get_new_incantation_operations(L: Array):
	#print("player " + str(game_id) + " got " + str(len(L))+ " new incantations")
	
	#re-generate the incantations from the dicts
	var list_of_incantations = []
	var incantation_operations = []
	for incantation in L:
		incantation_operations.clear()
		for dict in incantation:
			incantation_operations.append(operation_factory.generate_operation_from_dict(dict))
		list_of_incantations.append(incantation_operations)
		#print("incantation added to list: " + str(list_of_incantations))
	my_domain.base_data.spellbook.store_new_incantations(list_of_incantations)
	
	#we are ready when we get the operations to play!
	if state == STATE.WAITING_EVERYONE:
		if get_tree().is_network_server():
			client_ready(game_id)
		else:
			rpc_id(1, "client_ready", game_id)
		print("ready to play!")
	
	input_handler.update_authorisation_to_input(true)

#the players rpc this function and the server determines the target
#or the target is given by the player
remote func player_meteor_incantation(gid, dico_threat):
	var who = get_tree().get_rpc_sender_id()
	print("Meteor incantation from player " + str(gid))
	if get_tree().is_network_server():
		#for now, random target...
		var target = operation_factory.choice(get_all_targetable_players(gid))
		print("Player " + str(gid) + " targets " + str(target))
		meteor_cast(gid, target, dico_threat)

remote func player_defense_command(gid, power):
	if get_tree().is_network_server():
		rpc("player_defense_command", gid, power)
		
	var domain = get_domain_by_gid(gid)
	if domain:
		domain.domain_field.magic_projectile_incantation(power)
	
func determine_target(dico_threat):
	pass
	
#is it faster ??
#no wtf
func generate_new_incantations_threaded(gid: int, n := 2):
	if get_tree().is_network_server():
		print("Threaded incantations generation for player " + str(gid))
		var domain = get_domain_by_gid(gid)
		if domain:
			var pid = domain.player_id
			var array_of_full_operation_list = []
			var pattern = domain.base_data.spellbook.pattern.get_list()
			var new_incantation_list = incantation_factory.generate_incantations(pattern, n)
			
			#we must store the operations inside the server
			domain.base_data.spellbook.store_new_incantations(new_incantation_list)
			
			#we send them only to other players (not bots)
			if (not domain.is_bot()) and gid != 1:
				#if we have to send them, we must generate the array containing 
				# the list of dicts of operations
				var array_of_full_operation_dicts_list = []
				for incantation in new_incantation_list:
					var incantation_list = []
					for op in incantation:
						incantation_list.append(operation_factory.generate_operation_dict_from_operation(op))
					array_of_full_operation_dicts_list.append(incantation_list)
				#print("sending the new incantations to " + str(gid))
				rpc_id(pid, "get_new_incantation_operations", array_of_full_operation_dicts_list)
			print("Incantations sent to player " + str(gid))


#generate n full patterns of operations for the player gid.
remote func generate_new_incantation_operations(gid: int, n := 2):
	if get_tree().is_network_server():
		#print("operations generation for player " + str(gid))
		var domain = get_domain_by_gid(gid)
		if domain:
			var pid = domain.player_id
			var array_of_full_operation_list = []
			var pattern = domain.base_data.spellbook.pattern.get_list()
			var new_operation_list = []
			var new_operation
			for i in range(n):
				new_operation_list = []
				for p_element in pattern:
					new_operation = operation_factory.generate(p_element)
					new_operation_list.append(new_operation)
				print(new_operation_list)
				array_of_full_operation_list.append(new_operation_list)
				print(str(array_of_full_operation_list))
				
			#we must store the operations inside the server
			domain.base_data.spellbook.store_new_incantations(array_of_full_operation_list)
			
			#we send them only to other players (not bots)
			if (not domain.is_bot()) and gid != 1:
				#if we have to send them, we must generate the array containing 
				# the list of dicts of operations
				var array_of_full_operation_dicts_list = []
				for incantation in array_of_full_operation_list:
					var incantation_list = []
					for op in incantation:
						incantation_list.append(operation_factory.generate_operation_dict_from_operation(op))
					array_of_full_operation_dicts_list.append(incantation_list)
				#print("sending the new incantations to " + str(gid))
				rpc_id(pid, "get_new_incantation_operations", array_of_full_operation_dicts_list)

func get_all_targetable_players(gid: int) -> Array:
	var targetable = []
	var iterated_domain_gid
	for domain in get_array_of_all_domains():
		iterated_domain_gid = domain.get_gid()
		if not domain.is_eliminated() and iterated_domain_gid != gid:
			targetable.append(iterated_domain_gid)
	return targetable
	
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
	
func get_array_of_alive_players() -> Array:
	var array = []
	for domain in get_array_of_all_domains():
		if not domain.is_eliminated():
			array.append(domain)
	return array
	
func is_waiting_for_transaction_end():
	return my_domain.spellbook.get_waiting_transaction()
	
func create_pop_up_notification(display_time: float, message: String, pos = 1):
	var popup = POPUPCLASS.instance()
	popup_nodes.add_child(popup)
	popup.initialize(display_time, message, pos)
	popup.change_position(Vector2(500, 600))
	popup.display_on_screen()

func _on_disconnected():
	leave_game()
	
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

#TODO: send the indexes of operations instead of the operation
func _on_bonus_menu_player_asks_for_action(gid, action_type, element):
	var money = my_domain.base_data.get_money()
	var cost = -1
	match(action_type):
		BonusMenuBis.BONUS_ACTION.BUY_OPERATION:
			#if the user wants to buy an operation, then
			#the element given is an instance of Operation_Display
			var op = bonus_window.get_new_operation_by_index(element[1])
			if op:
				cost = op.get_price()
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
			message = "Pas assez d'argent, ??conomisez!"
		Spellbook.BUYING_OP_ATTEMPT_RESULT.NOT_ERASABLE:
			message = "Vous ne pouvez pas retirer plus d'op??rations !"
		Spellbook.BUYING_OP_ATTEMPT_RESULT.NO_SPACE:
			message = "Vous ne pouvez pas compl??ter davantage votre Incantation !"
		Spellbook.BUYING_OP_ATTEMPT_RESULT.ERROR:
			message = "Erreur lors de l'achat"
	
	var can_buy = buy_status == Spellbook.BUYING_OP_ATTEMPT_RESULT.CAN_BUY
	if can_buy:
		#expecting more action from the user
		match(action_type):
			BonusMenuBis.BONUS_ACTION.SWAP_OPERATIONS:
				bonus_window.change_state(BonusMenu.STATE.SWAPPING)
			BonusMenuBis.BONUS_ACTION.ERASE_OPERATION:
				bonus_window.change_state(BonusMenu.STATE.SELECTING)
			BonusMenuBis.BONUS_ACTION.BUY_OPERATION:
				#in this case, element is an array [op, index of op in shop]
				if get_tree().is_network_server():
					ask_server_for_bonus_action(gid, action_type, [element[1]])
				else:
					rpc_id(1, "ask_server_for_bonus_action", gid, action_type, [element[1]])
	else:
		create_pop_up_notification(display_time, message,pos)
	
remote func player_eliminated(gid: int):
	var domain = get_domain_by_gid(gid)
	if domain:
		domain.apply_elimination_ui()
	
	if get_tree().is_network_server():
		var nb_remaining_players = len(get_array_of_alive_players())
		game_data["eliminations"].append(gid)
		#TODO: put base_data elimination !
		print("remaining players: " + str(nb_remaining_players))
		ready_label.text = "Restants: " + str(nb_remaining_players)
		if nb_remaining_players <= 1:
			end_of_game()
	
	
#we must evaluate the number of remaining players to stop the game if needed
func _on_enemy_elimination(gid: int):
	if get_tree().is_network_server():
		player_eliminated(gid)

func _on_InputHandler_keyboard_action(action):
	pass
	
func _on_InputHandler_check_answer_command():
	print("checking answer command")
	# we don't need to send the operation because the server
	# already has it, and the good position
	var ans = operation_display.get_answer()
	var gid = game_id
	if get_tree().is_network_server():
		check_answer(ans, gid)
	else:
		rpc_id(1, "check_answer", ans, gid)

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


func _on_bonus_menu_operations_selection_done(L, bonus_menu_state):
	var action_type
	match(bonus_menu_state):
		BonusMenuBis.STATE.IDLE:
			pass
		BonusMenuBis.STATE.SWAPPING:
			action_type = BonusMenuBis.BONUS_ACTION.SWAP_OPERATIONS
		BonusMenuBis.STATE.SELECTING:
			action_type = BonusMenuBis.BONUS_ACTION.ERASE_OPERATION
			
	print("Sending request for buying selection...")
	if Gamestate.player_info["net_id"] != 1:
		rpc_id(1, "ask_server_for_bonus_action", game_id, action_type, L)
	else:
		ask_server_for_bonus_action(game_id, action_type, L)

func _on_spellbook_meteor_invocation(gid, dico_threat):
	print("Meteor invocation !")
	if get_tree().is_network_server():
		player_meteor_incantation(gid, dico_threat)
	else:
		rpc_id(1, "player_meteor_incantation", dico_threat)
		
func _on_spellbook_defense_command(gid, power):
	print("Defense command from player " + str(gid))
	if get_tree().is_network_server():
		player_defense_command(gid, power)
	else:
		rpc_id(1, "player_defense_command", gid, power)

func _on_spellbook_low_incantations_stock(gid):
	if get_tree().is_network_server():
		print("Low stock for " + str(gid))
		generate_new_incantation_operations(gid, 4)


func _on_spellbook_incantation_has_changed(gid, L):
	var domain = get_domain_by_gid(gid)
	if domain == my_domain:
		domain.incantation_has_changed(L)
	
	#on the server side, if it is not a bot
	if gid == game_id:
		#update incantation in bonus_menu
		bonus_window.set_pattern(L)
		
		#we have to wait the server to send new incantations
		input_handler.update_authorisation_to_input(false)
		
func _on_spellbook_operation_to_display_has_changed(gid, new_op):
	print("domain " + str(gid) + " must change the operation to display")
	if gid == game_id:
		print("i must change the operation to display")
		operation_display.change_operation_display(new_op)
		input_handler.update_authorisation_to_input(true)

func _on_spellbook_incantation_progress_changed(gid, n):
	if get_tree().is_network_server():
		incantation_progress_changed(gid, n)
	else:
		rpc_id(1, "incantation_progress_changed", gid, n)
	
func _on_spellbook_potential_value_changed(gid, x):
	if get_tree().is_network_server():
		potential_value_changed(gid, x)
	else:
		rpc_id(1, "potential_value_changed", gid, x)
	
func _on_spellbook_defense_power_changed(gid, x):
	if get_tree().is_network_server():
		defense_power_changed(gid, x)
	else:
		rpc_id(1, "defense_power_changed", gid, x)
	
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
	print("Meteor impact detected in domain " + str(gid))
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


func _on_leave_game_button_down():
	leave_game()
