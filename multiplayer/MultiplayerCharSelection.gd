extends Control

enum STATE{
	SELECTING=1,
	START_COUNTDOWN,
	LAUCHING
}

const confirmed_color = Color(0.11,0.92,0.08)
const waiting_confirmation_color = Color(0.98,0.11,0.13)

#{index de ItemList: clef de global.characters}
var association = {}

var title_label
var diff_label
var diff_slider

var selection_state

var state
onready var character_list = $vbox_info/VBoxContainer/CenterContainer/characters
onready var char_info_node = $self_char_info
onready var player_list = $MultipleCharacterDisplay
onready var scene_transition = $SceneTransitionRect 
onready var panel_chat = $HUD/PanelOnlineChat

onready var add_bot_bt = $vbox_info/VBoxContainer/HBoxContainer/add_bot
onready var remove_bot_bt = $vbox_info/VBoxContainer/HBoxContainer/remove_bot

func _ready():
	state = STATE.SELECTING
	if get_tree().is_network_server():
		add_bot_bt.disabled = false
		remove_bot_bt.disabled = false
		
	print("Arrivée dans le lobby")
	print("Server data:")
	print(str(network.server_info))
	scene_transition.play(true)
	SoundPlayer.play_bg_music("titlescreen")
	
	character_list.icon_mode = ItemList.ICON_MODE_TOP
	character_list.select_mode = ItemList.SELECT_SINGLE
	character_list.same_column_width = true
	var k = 0
	# adding char sprite in item list
	for charkey in global.char_data.keys():
		var character = global.char_data[charkey]
		var tex = global.get_resized_ImageTexture(character.get_icon_texture(), 128, 128)
		character_list.add_icon_item(tex)
		association[k] = charkey
		k = k+1
		
	network.connect("player_list_changed", self, "_on_player_list_changed")
	network.connect("bot_list_changed", self, "_on_bot_list_changed")
	
	network.connect("player_added", self, "_on_player_added")
	network.connect("player_removed", self, "_on_player_disconnected")
	network.connect("bot_added", self, "_on_bot_added")
	network.connect("bot_removed", self, "_on_bot_removed")
	# Must act if disconnected from the server
	network.connect("disconnected", self, "_on_disconnected")
	get_tree().connect("network_peer_connected", self, "_on_player_connected")
	#get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	get_tree().connect("server_disconnected", self, "_on_disconnected_from_server")
		
	# If we connect while the other player has already selected 
	# a character, it must appear on the screen
	ui_player_list()
	ui_bot_list()
	update_character_select()
	char_info_node.add_player(Gamestate.player_info["pseudo"], Gamestate.player_info["net_id"])

func leave_scene(dest: String):
	scene_transition.change_scene(dest)

remote func change_screen_data(char_selected_id: int, player: int):
	var character = global.char_data[char_selected_id]
	print("Player " + str(player) + " has selected character " + str(char_selected_id))
	
	if char_info_node.get_id_player() == player :
		char_info_node.select_character(char_selected_id)
	else:
		var player_node = player_list.get_player_by_id(player)
		if player_node:
			print("AAA")
			player_node.select_character(char_selected_id)
		else:
			print("change_screen_data: player not found ??")
			player_list.add_player(network.players[player]["pseudo"], player, char_selected_id)

func update_character_select():
	if get_tree().is_network_server():
		# we send to every client (except the server)
		# the data of characters selected
		for id in network.players:
			var player_data = network.players[id]
			#if the player id is not in the display list, we create it
			if not player_list.get_player_by_id(id) and id != 1:
				#print("update_char_select: player not found ???")
				generate_character_display_node(player_data["pseudo"], 
												player_data["net_id"], 
												player_data["game_id"], 
												player_data["id_character_selected"], 
												player_data["character_validated"],
												false)
												
			if player_data["id_character_selected"] != -1 :
				#print("Sending character selected from player " + str(id))
				rpc("change_screen_data", player_data["id_character_selected"], id)
				
			if player_data["character_validated"]:
				#print("player " + str(id) + " has already validated")
				rpc("ui_validate_choice", id)
				
		for id in network.bots:
			var player_data = network.bots[id]
			#if the player id is not in the display list, we create it
			if not player_list.get_player_by_id(id) and id != 1:
				#print("update_char_select: player not found ???")
				generate_character_display_node(player_data["pseudo"], 
												player_data["net_id"], 
												player_data["game_id"], 
												player_data["id_character_selected"], 
												false, true)
												
			if player_data["id_character_selected"] != -1 :
				#print("Sending character selected from player " + str(id))
				rpc("change_screen_data", player_data["id_character_selected"], id)
				
			if player_data["character_validated"]:
				#print("player " + str(id) + " has already validated")
				rpc("ui_validate_choice", id)
				
remote func character_selection(id_character, net_id):
	if (get_tree().is_network_server()):
		rpc("character_selection", id_character, net_id)
		#we update this information in the network
		network.players[net_id]["id_character_selected"] = id_character
	# Now to code that will be executed regardless of being on client or server
	print("Character " + str(id_character) + " selected by client id " + str(net_id))
	
	#we update the gamestate id char information
	Gamestate.player_info["id_character_selected"] = id_character
	#and on the network
	network.players[net_id]["id_character_selected"] = id_character
	#then we apply modifications on the screen
	change_screen_data(id_character, net_id)
	
remotesync func clear_selection(net_id):
	print("Client id " + str(Gamestate.player_info["net_id"])+" : Char selection cancel for player " + str(net_id))
	
	if char_info_node.get_id_player() == net_id :
		char_info_node.cancel_validation()
	else:
		var player_node = player_list.get_player_by_id(net_id)
		if player_node:
			player_node.cancel_validation()

	network.players[net_id]["id_character_selected"] = -1
	network.players[net_id]["character_selected"] = false

	Gamestate.player_info["character_validated"] = false
	Gamestate.player_info["id_character_selected"] = -1

	#print_other_player_label_node()
	#if we are the one cancelling the choice, then we change color
	#of our specific name label
#	if net_id == Gamestate.player_info["net_id"]:
#		$HUD/PanelPlayerList/lblLocalPlayer.set("custom_colors/font_color",waiting_confirmation_color)
#	else:
#		#error here...incorrect name ???
#		$HUD/PanelPlayerList/boxList.get_node("client"+str(net_id)).set("custom_colors/font_color",waiting_confirmation_color)

remote func ui_validate_choice(net_id):
	if char_info_node.get_id_player() == net_id :
		char_info_node.validate_choice()
	else:
		var player_node = player_list.get_player_by_id(net_id)
		if player_node:
			player_node.validate_choice()
	# Visual interaction to show player is ready?
	# if the func is called by this client, then 
	# we change local player label color
#	if net_id == Gamestate.player_info["net_id"]:
#		$HUD/PanelPlayerList/lblLocalPlayer.set("custom_colors/font_color",confirmed_color)
#	else:
#		# node not found on client: must be initialized!
#		var node_to_change = $HUD/PanelPlayerList/boxList.get_node("client"+str(net_id))
#		node_to_change.set("custom_colors/font_color",confirmed_color)

remotesync func ui_validate_all_bots():
	for id in network.bots:
		var bot_node = player_list.get_bot_by_id(id)
		bot_node.validate_choice()

remote func ui_player_list():
	print("ui_player_list Player " + str(Gamestate.player_info["net_id"]))
	
	# Then we do the same to the MultipleCharDisplay
	for player in player_list.get_players_display_nodes():
		player_list.remove_player_by_id(player.get_id_player())
		
	# Now iterate through the player list creating a new entry into the boxList
	# and in MultipleCharDisplay
	for player_dict in network.players.values():
		#our ID is not supposed to be inside the box
		if (player_dict["net_id"] != Gamestate.player_info["net_id"]):
			generate_character_display_node(player_dict["pseudo"], player_dict["net_id"], player_dict["game_id"], player_dict["id_character_selected"], player_dict["character_validated"], false)
			print("Player " + str(player_dict["net_id"]) + " added in player list!")
	
remote func ui_bot_list():
	print("ui_bot_list Player " + str(Gamestate.player_info["net_id"]))
	
	for bot in player_list.get_bot_display_nodes():
		player_list.remove_bot_by_id(bot.get_id_player())
		
	# Now iterate through the player list creating a new entry into the boxList
	# and in MultipleCharDisplay
	for player_dict in network.bots.values():
		#our ID is not supposed to be inside the box
		if (player_dict["net_id"] != Gamestate.player_info["net_id"]):
			generate_character_display_node(player_dict["pseudo"], player_dict["net_id"], player_dict["game_id"], player_dict["id_character_selected"], player_dict["character_validated"], true)
			print("Bot " + str(player_dict["net_id"]) + " added in player list!")
		
remote func change_bot_diff(bot_id, new_diff):
	if get_tree().is_network_server():
		for id in network.players:
			# Send new player info to currently iterated player, skipping the server (which will get the info shortly)
			rpc("change_bot_diff", bot_id, new_diff)
				
	network.bots[bot_id]["bot_diff"] = new_diff
	var bot_display = player_list.get_bot_by_id(bot_id)
	if bot_display:
		bot_display.set_bot_diff(new_diff)
	
remote func change_bot_character(bot_id, new_char_id):
	if get_tree().is_network_server():
		rpc("change_bot_character", bot_id, new_char_id)
				
	network.bots[bot_id]["id_character_selected"] = new_char_id
	var bot_display = player_list.get_bot_by_id(bot_id)
	if bot_display:
		bot_display.select_character(new_char_id)
		
remotesync func write_message(sender, msg, server = false): 
	panel_chat.write_message(msg)
	
remotesync func validate_choice(net_id):
	if get_tree().is_network_server():
		network.players[net_id]["character_validated"] = true
		print("Player " + str(net_id) + " is now ready!")
		
		# if at least two players are ready (or there is 1 player and bots), 
		# then the game may start.
		if is_everyone_ready() and network.get_total_players_entities() > 1:
			#we validate bot character display
			network.update_all_players_data()
			rpc("ui_validate_all_bots")
			rpc("write_message", 1, "Tous les joueurs sont prêts!")
			rpc("start_game")
			
	#visual indication
	ui_validate_choice(net_id)
	
remotesync func start_game():
	state = STATE.START_COUNTDOWN
	#Starting after 2 seconds
	for i in range(2,-1,-1):
		#Each second, we write the countdown in player chat
		yield(get_tree().create_timer(1),"timeout")
		if state == STATE.START_COUNTDOWN:
			panel_chat.write_message(str(i) + "...")
		else:
			cancel_start()
			break

	if state == STATE.START_COUNTDOWN:
		state = STATE.LAUCHING
		for id in network.players:
			network.players[id]["id_character_playing"] = network.players[id]["id_character_selected"]
		leave_scene("res://multiplayer/GameFieldMulti.tscn")

# called if a player disconnects while the game is starting.
remotesync func cancel_start():
	state = STATE.SELECTING
	panel_chat.write_message("Lancement annulé...")
	
func generate_character_display_node(name_player: String, id_player: int, gid: int, id_character: int, validated = false, is_bot = false):
	var player_node = global.character_display.instance()
	
	#we add the node in the player list
	player_list.add_player_node(player_node, is_bot)
	
	player_node.cancel_validation()
	player_node.connect("bot_diff_changed", self, "_on_bot_diff_changed")
	player_node.connect("character_changed", self, "_on_bot_character_changed")
	player_node.set_name(str(id_player))
	player_node.add_player(name_player, id_player, gid)
	
	print("Player " + str(gid) + ": character " + str(id_character))
	if id_character != -1:
		player_node.select_character(id_character)
	if validated:
		player_node.validate_choice()

	if is_bot:
		player_node.set_bot(true)
	
	return player_node
	

func is_everyone_ready():
	var nb_ready = 0
	for id in network.players:
		print(network.players)
		if network.players[id]["character_validated"]:
			nb_ready += 1
	return nb_ready == len(network.players)
	
func _on_return_button_down():
	global.game_mode = 0
	print("End of connection")
	network.end_connection()
	leave_scene("res://scenes/titlescreen/title.tscn")

func _on_characters_item_selected(index):
	# when a player selects a character, he musts tells the
	# server to show it to the other
	print("Case cliquée: " + str(index))
	#if you validate your choice, you can't change the character.
	if not Gamestate.player_info["character_validated"]:
		var char_selected_id = association[index]
		if get_tree().is_network_server():
			character_selection(char_selected_id, Gamestate.player_info["net_id"])
		else:
			rpc_id(1, "character_selection", char_selected_id, Gamestate.player_info["net_id"])

func _on_play_button_down():
	if Gamestate.player_info["id_character_selected"] != -1:
		print("Validation id client " + str(Gamestate.player_info["net_id"]))
		rpc("validate_choice", Gamestate.player_info["net_id"])
	else:
		panel_chat.write_message("Validation impossible: aucun personnage sélectionné.")

func _on_cancel_choice_button_down():
	var who = get_tree().get_rpc_sender_id()
	character_list.unselect_all()
	print("Annulation choix par id client " + str(Gamestate.player_info["net_id"]))
	rpc("clear_selection", Gamestate.player_info["net_id"])
	

func _on_player_list_changed():
	print("Player list has changed.")
	ui_player_list()
	
func _on_bot_list_changed():
	print("Bot list has changed.")
	ui_bot_list()
	
func _on_player_connected(id):
	print("Player " + str(id) + " has connected to the server...")
	
func _on_player_added(id):
	var player_data = network.players[id]
	generate_character_display_node(player_data["pseudo"], player_data["net_id"], player_data["game_id"], player_data["id_character_selected"], player_data["character_validated"], false)
	
func _on_bot_added(id):
	print("Ajout du bot dans l'interface")
	var player_data = network.bots[id]
	generate_character_display_node(player_data["pseudo"], player_data["net_id"], player_data["game_id"], player_data["id_character_selected"], false, true)
	
func _on_bot_diff_changed(id, diff):
	if get_tree().is_network_server():
		change_bot_diff(id, diff)
	
func _on_bot_character_changed(id, new_char_id):
	if get_tree().is_network_server():
		change_bot_character(id, new_char_id)
	
func _on_player_disconnected(pinfo):
	player_list.remove_player_by_id(pinfo["net_id"])
	panel_chat.write_message(pinfo["pseudo"] + " a été déconnecté du serveur.")
	# if a players disconnects during the game start countdown
	# then we stop the countdown
	match state:
		STATE.SELECTING:
			pass
		STATE.START_COUNTDOWN:
			state = STATE.SELECTING
		STATE.LAUCHING:
			pass

func _on_bot_removed(binfo):
	player_list.remove_bot_by_id(binfo["net_id"])
	
func _on_connected_to_server():
	print("Connected to the server.")
	print("player list: " + str(network.players))
	ui_player_list()
	#when a player connects, we must send him the data
	update_character_select()
	
func _on_connection_failed():
	pass
	
func _on_disconnected_from_server():
	leave_scene("res://multiplayer/Onirilobby.tscn")
	
func _on_disconnected():
	leave_scene("res://multiplayer/Onirilobby.tscn")

func _on_add_bot_button_down():
	if get_tree().is_network_server():
		if state == STATE.SELECTING:
			#no dict here because the server's network node will generate it
			network.register_bot()

#Removes the last bot added in the room
func _on_remove_bot_button_down():
	if get_tree().is_network_server():
		if state == STATE.SELECTING:
			var index = network.get_nb_bots()-1
			print("index bot to remove: " + str(index))
			var node_to_remove = player_list.get_bot_by_index(index)
			if node_to_remove:
				var id_bot_to_remove = node_to_remove.get_id_player()
				network.unregister_bot(id_bot_to_remove)
			else:
				print("Incorrect index")
			
func _on_MultipleCharacterDisplay_bot_diff_changed_bis(id, value):
	change_bot_diff(id, value)
