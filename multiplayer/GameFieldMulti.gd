extends Node2D

const ROUND_TIME = 40.0
const PREROUND_TIME = 5.0
const SHOPPING_TIME = 15.0

enum STATE{
	WAITING_EVERYONE = 1,
	PREROUND,
	ROUND,
	SHOPPING,
	ENDED
}
signal domain_answer_response(id_domain, good_answer)
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


# Called when the node enters the scene tree for the first time.
func _ready():
	game_id = Gamestate.player_info["game_id"]
	# Connect event handler to the player_list_changed signal
	network.connect("player_list_changed", self, "_on_player_list_changed")
	
	#We must remove the player if he leaves
	network.connect("network_peer_disconnected", self, "_on_player_disconnected")
	
	#or stop the game if we are disconnected
	network.connect("server_disconnected", self, "_on_disconnected_from_server")
	
	# Must act if disconnected from the server
	network.connect("disconnected", self, "_on_disconnected")
	
	state = STATE.WAITING_EVERYONE
	
	round_time = ROUND_TIME
	preround_time = PREROUND_TIME
	shopping_time = SHOPPING_TIME
	
	var my_id = Gamestate.player_info["net_id"]
	my_domain.initialise(my_id)
	
	my_domain.base_data.spellbook.connect("meteor_invocation", self, "_on_spellbook_meteor_invocation")
	my_domain.base_data.spellbook.connect("defense_command", self, "_on_spellbook_defense_command")
	my_domain.base_data.spellbook.connect("low_incantations_stock", self, "_on_spellbook_low_incantations_stock")
	operation_factory = OperationFactory.new()
	
	#everyone has already the data to spawn every single player
	spawn_players()

	targets = {}
	time_display.set_min_value(0)
	round_timer.start(preround_time)
	
	if get_tree().is_network_server():
		client_ready(1)
	else:
		rpc_id(1, "client_ready", game_id)
		
	pause_mode = true
	
func _process(delta):
	if not pause_mode:
		game_time += delta
	time_display.set_new_value(round_timer.time_left)
	
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
		generate_actor(network.players[id])
	for id in network.bots:
		generate_actor(network.bots[id])
		
#called to tell everyone the game is about to start
remote func client_ready(gid: int):
	clients_ready_to_play.append(gid)
	if get_tree().is_network_server():
		for id in network.players:
			if id != 1:
				rpc_id(id, "client_ready", gid)
		#might cause problems ?
		if len(clients_ready_to_play) == network.get_nb_players():
			rpc("game_about_to_start")

#note: meteor and projectile casts are only visual in clients: if it is display
#on a basedomaindisplay, then it's not the main character so they should
#not send data from other players.

func generate_actor(pinfo):
	# Load the scene and create an instance
	var pclass = load(pinfo["actor_path"])
	var nactor = pclass.instance()
	
	# domain initialization
	nactor.create(pinfo["id_character_playing"])
	
	# If this actor does not belong to the server, change the node name and network master accordingly
	if (pinfo["net_id"] != 1):
		nactor.set_network_master(pinfo["net_id"])
	
	nactor.set_name(str(pinfo["net_id"]))
	if pinfo["is_bot"]:
		bot_game_data[pinfo["game_id"]]["shop_operations"] = []
		nactor.set_name("bot_"+str(pinfo["net_id"]))
		var bot_diff = pinfo["bot_diff"]
		nactor.ai_node.set_hardness(bot_diff)
		nactor.activate_AI()
		
	# Finally add the actor into the world
	enemy_domains.add_child(nactor)

	#we add connections (elimination, meteor cats, projectile cast, etc)
	#elimination signal
	nactor.base_data.connect("eliminated", self, "_on_enemy_elimination")
	#connection to the input handler
	nactor.base_data.input_handler.connect("check_answer_command", self, "_on_check_answer_command")
	nactor.base_data.input_handler.connect("changing_stance_command", self, "_on_changing_stance_command")
	nactor.base_data.input_handler.connect("delete_digit", self, "_on_delete_digit")
	nactor.base_data.input_handler.connect("write_digit", self, "_on_write_digit")
	
	#send signal to tell everyone this bot is ready
	if get_tree().is_network_server() and pinfo["is_bot"]:
		client_ready(pinfo["game_id"])
		
#called to tell all clients the game can start
remotesync func game_about_to_start():
	pause_mode = false
	changing_state(STATE.PREROUND)
	
#we are not supposed to jump states, but just in case,
#we give the new state as an argument
#TO BE CONTINUED
remote func changing_state(new_state):
	if get_tree().is_network_server():
		match(new_state):
			STATE.PREROUND:
				new_round()
			STATE.ROUND:
				pass #RAF
			STATE.SHOPPING:
				#will call rpc in all clients
				generate_all_shop_operations()
			STATE.ENDED:
				pass #TO BE CONTINUED
				
		for id in network.players:
			if id != 1:
				rpc_id(id, "changing_state", new_state)
		
	match(new_state):
		STATE.PREROUND:
			round_timer.start(preround_time)
			time_display.set_max_value(preround_time)
			bonus_window.hide = true
		STATE.ROUND:
			pause_mode_activation(false)
			round_timer.start(round_time)
			time_display.set_max_value(round_time)
		STATE.SHOPPING:
			pause_mode_activation(true)
			bonus_window.hide = false
			round_timer.start(shopping_time)
			time_display.set_max_value(shopping_time)
		STATE.ENDED:
			bonus_window.hide = false
			pause_mode_activation(true)
			
			
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
				
	var targetted_domain = get_domain_by_gid(gid)
	if targetted_domain:
		targetted_domain.base_data.spellbook.set_stance(new_stance)
	emit_signal("changing_stance_command", new_stance)
	
#attack from pid to target_id
remote func meteor_cast(gid: int, target_game_id: int, threat_data: Dictionary):
	if get_tree().is_network_server():
		#data must be sent to everyone by the server
		for id in network.players:
			if id != 1:
				rpc_id(id, "meteor_cast", gid, target_game_id, threat_data)

	var targetted_domain = get_domain_by_gid(target_game_id)
	if targetted_domain:
		targetted_domain.domain_field.add_threat(gid, threat_data, false)

remote func meteor_remove(gid: int, meteor_id: int):
	if get_tree().is_network_server():
		for id in network.players:
			if id != 1:
				rpc_id(id, "meteor_remove", gid, meteor_id)
			#since bots are controlled by server, their meteors
			#destroy themselves
			
	var target_domain = get_domain_by_gid(gid)
	if target_domain:
		target_domain.domain_field.remove_meteor(meteor_id)
	
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
	if get_tree().is_network_server():
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
			for id in network.players:
				if id != 1:
					rpc_id(id, "result_answer", gid, stat_calcul[5])
			#we store it in the list
			game_stats.append(stat_calcul)
			
			#then we call it on ourself
			result_answer(gid, stat_calcul[5])
	
#called from server by check_answer
remote func result_answer(gid, good_answer: bool):
	emit_signal("domain_answer_response", gid, good_answer)

remote func damage_taken(gid: int, n: int):
	if get_tree().is_network_server():
		for id in network.players:
			if id != 1:
				rpc_id(id, "damage_taken", gid, n)

	var target_domain = get_domain_by_gid(gid)
	if target_domain:
		target_domain.base_data.get_damage(n)

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
remote func ask_server_for_bonus_action(action_type, L: Array):
	var who = get_tree().get_rpc_sender_id()
	if get_tree().is_network_server():
		var domain = get_domain_by_pid(who)
		if domain:
			var already_buying = domain.is_waiting_for_transaction_end()
			if already_buying:
				rpc_id(who, "server_answer_for_bonus_action", false, Spellbook.BUYING_OP_ATTEMPT_RESULT.ALREADY_BUYING)
				return

			#checking if the action is possible according to 
			#the data in the server
			var buy_status = check_shop_operation(who, action_type, L[0])
			
			if Gamestate.player_info["net_id"] != 1:
				rpc_id(1, "server_answer_for_bonus_action", buy_status, action_type, L)
				#then we apply modifications on the server
		
				if buy_status == Spellbook.BUYING_OP_ATTEMPT_RESULT.CAN_BUY:
					match(action_type):
						BonusMenuBis.BONUS_ACTION.BUY_OPERATION:
							domain.shop_action(action_type, L[0].get_price(), L[0])
						BonusMenuBis.BONUS_ACTION.ERASE_OPERATION:
							domain.shop_action(action_type, L[0].get_price(), L[0])
						BonusMenuBis.BONUS_ACTION.SWAP_OPERATIONS:
							pass
			else:
				server_answer_for_bonus_action(buy_status, action_type, L)
			
			
remote func server_answer_for_bonus_action(answer_type, action_type, L):
	var display_time = 3.0
	var message = ""
	var pos = 1
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
		Spellbook.BUYING_OP_ATTEMPT_RESULT.NO_MONEY:
			message = "Pas assez d'argent, économisez !"
		Spellbook.BUYING_OP_ATTEMPT_RESULT.NO_SPACE:
			message = "Vous ne pouvez pas compléter davantage votre Incantation !"
		Spellbook.BUYING_OP_ATTEMPT_RESULT.ERROR:
			message = "Erreur lors de l'achat..."

	create_pop_up_notification(display_time, message,pos)
	#emit signal to update the UI ?
	#
	
#TO BE CONTINUED
remote func new_round():
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
	set_pause_mode(b)

#only the server can generate the new operations 
#for each player.
func generate_all_shop_operations():
	if get_tree().is_network_server():
		#dict of all new operations from all players
		var new_op_dict = {}
		var all_domains_array = get_array_of_all_domains()
		#we first generate all new operations from all players
		#(bots included)
		for domain in all_domains_array:
			var id = domain.game_id
			
			if domain:
				var operation_preference = domain.spellbook.get_operation_preference()
				var difficulty_preference = domain.spellbook.get_difficulty_preference()
				var n = domain.get_nb_new_operations()
				new_op_dict[id] = []
				for i in range(n):
					var type = ponderate_random_choice_dict(operation_preference)
					var diff = ponderate_random_choice_dict(difficulty_preference)
					var new_op_data = [type,diff] 
					new_op_dict[id].append(new_op_data)
					
		#the player have also access to a part of operations
		#from the enemies. Now we can do it.
		var new_op_enemies_dict = {}
		
		for domain in all_domains_array:
			var id = domain.game_id
				
			if domain:
				new_op_enemies_dict[id] = []
				#we should create the list of all players
				#except the one considered here.
				var all_players_id = network.players.keys()
				
				all_players_id.erase(id)
				var n = domain.spellbook.get_inspiration()
				for i in range(n):
					#each time, we choose a random op
					# from a random player
					var player_tirage = all_players_id[randi() % all_players_id.size()]
					var operation = new_op_dict[player_tirage][randi()% new_op_dict[player_tirage].size()]
					var type = operation.get_type()
					var diff = operation.get_diff()
					new_op_enemies_dict[id].append([type,diff, player_tirage])
		
			#now we can send the data to the player
			#only if the domain is not one of a bot !
			if not domain.is_bot():
				rpc_id(id, "send_shop_operations", new_op_dict[id], new_op_enemies_dict[id])
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
	my_domain.base_data.spellbook.charge_new_incantations(L)
	
#the players rpc this function and the server determines the target
#or the target is given by the player
remote func player_meteor_incantation(dico_threat):
	var who = get_tree().get_rpc_sender_id()
	if get_tree().is_network_server():
		#for now, random target...
		var target = operation_factory.choice(get_all_targetable_players(who))
		#rpc_id(targe)
remote func player_defense_command(power):
	if get_tree().is_network_server():
		pass
	
func determine_target(dico_threat):
	pass
	
#generate n full patterns of operations for the player gid.
remote func generate_new_incantation_operations(gid: int, n = 2):
	var pid = get_tree().get_rpc_sender_id()
	if get_tree().is_network_server():
		var domain = get_domain_by_gid(gid)
		if domain:
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
	var popup = PopUpNotification.new()
	popup.initialize(display_time, message, pos)
	popup_nodes.add_child(popup)
	popup.display_on_screen()
	
func _on_threat_impact(meteor_id, threat_type, current_hp, power):
	#we only act if it is a node in our field
	if Gamestate.player_info["net_id"] != 1:
		rpc_id(1, "meteor_remove", my_domain.id_domain, meteor_id)
		rpc_id(1, "damage_taken", my_domain.id_domain, power)
	else:
		meteor_remove(my_domain.id_domain, meteor_id)

func _on_threat_destroyed(meteor_id, threat_type, power):
	if Gamestate.player_info["net_id"] != 1:
		rpc_id(1, "meteor_remove", my_domain.id_domain, meteor_id)
	else:
		meteor_remove(my_domain.id_domain, meteor_id)

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
		var next_state = (state+1)%len(STATE)
		changing_state(next_state)

func _on_bonus_menu_players_asks_for_action(action_type, element):
	var money = my_domain.get_money()
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
				if Gamestate.player_info["net_id"] != 1:
					rpc_id(1, "ask_server_for bonus_action", action_type, element)
				else:
					ask_server_for_bonus_action(action_type, element)
	else:
		create_pop_up_notification(display_time, message,pos)
		
func _on_enemy_elimination(pid: int):
	pass

func _on_InputHandler_changing_stance_command(new_stance):
	if get_tree().is_network_server():
		changing_stance(1, new_stance)
	else:
		rpc_id(1, "changing_stance",game_id, new_stance)

func _on_InputHandler_check_answer_command():
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
		rpc_id(1, "ask_server_for bonus_action", action_type, L)
	else:
		ask_server_for_bonus_action(action_type, L)

func _on_spellbook_meteor_invocation(dico_threat):
	if get_tree().is_network_server():
		player_meteor_incantation(dico_threat)
	else:
		rpc_id(1, "player_meteor_incantation", dico_threat)
		
func _on_spellbook_defense_command(power):
	if get_tree().is_network_server():
		player_defense_command(power)
	else:
		rpc_id(1, "player_defense_command", power)

func _on_spellbook_low_incantations_stock():
	rpc_id(1, "generate_new_incantation_operations", Gamestate.player_info["net_id"], 2)
