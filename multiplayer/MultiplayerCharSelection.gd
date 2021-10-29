extends CanvasLayer

const confirmed_color = Color(0.11,0.92,0.08)
const waiting_confirmation_color = Color(0.98,0.11,0.13)

#{index de ItemList: clef de global.characters}
var association = {}

var title_label
var diff_label
var diff_slider

var selection_state

onready var character_list = $vbox_info/VBoxContainer/CenterContainer/characters
onready var char_info_node = $self_char_info
onready var player_list = $MultipleCharacterDisplay
onready var scene_transition = $SceneTransitionRect 
onready var panel_chat = $HUD/PanelOnlineChat

func _ready():
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
	# Must act if disconnected from the server
	network.connect("disconnected", self, "_on_disconnected")
	get_tree().connect("network_peer_connected", self, "_on_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	get_tree().connect("server_disconnected", self, "_on_disconnected_from_server")
		
	# If we connect while the other player has already selected 
	# a character, it must appear on the screen
	update_character_select()
	ui_player_list()
	char_info_node.add_player(Gamestate.player_info["pseudo"], Gamestate.player_info["net_id"])

remote func change_screen_data(char_selected_id: int, player: int):
	var character = global.char_data[char_selected_id]
	print("Player " + str(player) + " has selected character " + str(char_selected_id))
	if char_info_node.get_player_id() == player :
		char_info_node.select_character(char_selected_id)
	else:
		print("prout")
		var player_node = player_list.get_player_by_id(player)
		if player_node:
			print("AAA")
			player_node.select_character(char_selected_id)
		else:
			print("change_screen_data: player not found ??")
			player_node.add_player(network.players[player]["pseudo"], player, char_selected_id)

func update_character_select():
	if get_tree().is_network_server():
		# we send to every client (except the server)
		# the data of characters selected
		for id in network.players:
				var char_selected = network.players[id]["id_character_selected"]
				var validated = network.players[id]["character_validated"]
				print("char_selected: " + str(char_selected))
				#if the player id is not in the display list, we create it
				if not player_list.get_player_by_id(id) and id != 1:
					print("update_char_select: player not found ???")
					player_list.add_player(network.players[id]["pseudo"], id)
				if char_selected != -1 :
					print("Sending character selected from player " + str(id))
					rpc("change_screen_data",char_selected, id)
					
				if validated:
					print("player " + str(id) + " has already validated")
					rpc("ui_validate_choice", id)
				
remotesync func character_selection(id_character,net_id):
	if (get_tree().is_network_server()):
		# We are on the server, so distribute the information throughout the connected players
		for id in network.players:
			# Send new player info to currently iterated player, skipping the server (which will get the info shortly)
			if (id != 1):
				rpc_id(id, "character_selection", id_character, net_id)
		#we update this information in the network
		network.players[net_id]["id_character_selected"] = id_character
	# Now to code that will be executed regardless of being on client or server
	print("Character " + str(id_character) + " selected by client id " + str(net_id))
	#we update the gamestate id char information
	Gamestate.player_info["id_character_selected"] = id_character
	
	#then we apply modifications on the screen
	change_screen_data(id_character, net_id)
	
remotesync func clear_selection(net_id):
	print("Client id " + str(Gamestate.player_info["net_id"])+" : Char selection cancel for player " + str(net_id))
	
	if char_info_node.get_player_id() == net_id :
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
	if char_info_node.get_player_id() == net_id :
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

remote func ui_player_list():
	print("ui_player_list Player " + str(Gamestate.player_info["net_id"]))
	
	# Then we do the same to the MultipleCharDisplay
	for player in player_list.get_players_display_nodes():
		player_list.remove_player_by_id(player.get_player_id())
		
	# Now iterate through the player list creating a new entry into the boxList
	# and in MultipleCharDisplay
	for p in network.players:
		#our ID is not supposed to be inside the box
		if (p != Gamestate.player_info["net_id"]):
			print("Player " + str(p) + " added in player list!")
			player_list.add_player(network.players[p]["pseudo"], p, network.players[p]["id_character_selected"], network.players[p]["character_validated"])

	print("Client nodes:")
	print_other_player_label_node()
	
remotesync func write_message(sender, msg, server = false): 
	panel_chat.write_message(msg)
	
remotesync func validate_choice(net_id):
	if get_tree().is_network_server():
		network.players[net_id]["character_validated"] = true
		print("Player " + str(net_id) + " is now ready!")
		
		#if the two players are ready, then the game may start.
		if is_everyone_ready() and len(network.players) > 1:
			rpc("write_message", 1, "Tous les joueurs sont prêts!")
			rpc("start_game")
			
	#visual indication
	ui_validate_choice(net_id)
	
remotesync func start_game():
	#Starting after 5 seconds
	for i in range(5,-1,-1):
		#Each second, we write the countdown in player chat
		yield(get_tree().create_timer(1),"timeout")
		panel_chat.write_message(str(i) + "...")
	leave_scene("res://multiplayer/GameFieldMulti.tscn")
	
func print_other_player_label_node():
	print("In client id " + str(Gamestate.player_info["net_id"]))
	for node in $HUD/PanelPlayerList/boxList.get_children():
		print(node.get_name() + str(node))
		
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
		rpc("character_selection", char_selected_id, Gamestate.player_info["net_id"])

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
	
func leave_scene(dest: String):
	scene_transition.play()
	yield(scene_transition,"transition_finished")
	get_tree().change_scene(dest)


func _on_player_list_changed():
	print("Players list has changed.")
	ui_player_list()
	
	
func _on_player_connected(id):
	print("Player " + str(id) + " now connected")
	
	
func _on_player_disconnected(id):
	pass
	
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
	pass
