extends Node

enum SELECTION_STATE{ZERO, ONE, TWO}

const confirmed_color = Color(0.11,0.92,0.08)
const waiting_confirmation_color = Color(0.92,0.11,0.08)
# if the game mode needs 2 characters to be selected
var two_character_selection: bool
#{index de ItemList: clef de global.characters}
var association = {}

var p1_data: Dictionary
var p2_data: Dictionary

var character_list
var title_label
var diff_label
var diff_slider

var selection_state
onready var scene_transition = $SceneTransitionRect 

onready var add_op_button := $vbox_info/VBoxContainer/HBoxContainer/add_op_button
onready var remove_op_button := $vbox_info/VBoxContainer/HBoxContainer/remove_op_button

func _ready():
	scene_transition.play(true)
	SoundPlayer.play_bg_music("titlescreen")
	var caracs_nodes_p1 = {
	"hp": {
		"name_label": $character_windows/char1/info/VBoxContainer/HBoxContainer/VBoxContainer/hp_label,
		"bar": $character_windows/char1/info/VBoxContainer/HBoxContainer/VBoxContainer2/hp_display,
	},
	"diff": {
		"name_label": $character_windows/char1/info/VBoxContainer/HBoxContainer/VBoxContainer/hardness_label,
		"bar": $character_windows/char1/info/VBoxContainer/HBoxContainer/VBoxContainer2/hardness_display,
	},
	"backlash": {
		"name_label": $character_windows/char1/info/VBoxContainer/HBoxContainer2/VBoxContainer/backlash_label,
		"bar": $character_windows/char1/info/VBoxContainer/HBoxContainer2/VBoxContainer2/backlash_display,
	}}
	var caracs_nodes_p2 = {
	"hp": {
		"name_label": $character_windows/char2/info/VBoxContainer/HBoxContainer/VBoxContainer/hp_label,
		"bar": $character_windows/char2/info/VBoxContainer/HBoxContainer/VBoxContainer2/hp_display,
	},
	"diff": {
		"name_label": $character_windows/char2/info/VBoxContainer/HBoxContainer/VBoxContainer/hardness_label,
		"bar": $character_windows/char2/info/VBoxContainer/HBoxContainer/VBoxContainer2/hardness_display,
	},
	"backlash": {
		"name_label": $character_windows/char2/info/VBoxContainer/HBoxContainer2/VBoxContainer/backlash_label,
		"bar": $character_windows/char2/info/VBoxContainer/HBoxContainer2/VBoxContainer2/backlash_display,
	}}
	caracs_nodes_p1["hp"]["bar"].set_reverse_gradient(true)
	caracs_nodes_p2["hp"]["bar"].set_reverse_gradient(true)
	caracs_nodes_p1["diff"]["bar"].set_reverse_gradient(false)
	caracs_nodes_p1["diff"]["bar"].set_reverse_gradient(false)
	caracs_nodes_p1["backlash"]["bar"].set_reverse_gradient(false)
	caracs_nodes_p1["backlash"]["bar"].set_reverse_gradient(false)
	
	p1_data = {}
	p2_data = {}
	p1_data["carac_nodes"] = caracs_nodes_p1
	p2_data["carac_nodes"] = caracs_nodes_p2
	
	p1_data["character_ID"] = -1
	p2_data["character_ID"] = -1
	
	p1_data["character_icon"] = $character_windows/char1/char_icon
	p2_data["character_icon"] = $character_windows/char2/char_icon
	p1_data["character_icon"].visible = false
	p2_data["character_icon"].visible = false
	p1_data["character_descr"] = $character_windows/char1/info/VBoxContainer/char_descr
	p2_data["character_descr"] = $character_windows/char2/info/VBoxContainer/char_descr
	
	p1_data["char_name_label"] = $character_windows/char1/info/VBoxContainer/name
	p2_data["char_name_label"] = $character_windows/char2/info/VBoxContainer/name
	
	p1_data["backlash_descr"] = $character_windows/char1/info/VBoxContainer/backlash_descr
	p2_data["backlash_descr"] = $character_windows/char2/info/VBoxContainer/backlash_descr
	
	p1_data["incantation_node"] = $character_windows/char1/info/Incantation
	p2_data["incantation_node"] = $character_windows/char2/info/Incantation
	
	p1_data["op_data"] = $character_windows/char1/info/VBoxContainer/VBoxContainer/GridContainer
	p2_data["op_data"] = $character_windows/char2/info/VBoxContainer/VBoxContainer/GridContainer
	p1_data["op_data"].visible = false
	p2_data["op_data"].visible = false
	
	title_label = $vbox_info/Label
	character_list = $vbox_info/VBoxContainer/CenterContainer/characters

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
	
	initialize_op_data(1)
	initialize_op_data(2)

	
	# Update the lblLocalPlayer label widget to display the local player name
	$HUD/PanelPlayerList/lblLocalPlayer.text = Gamestate.player_info["pseudo"]
	$HUD/PanelPlayerList/lblLocalPlayer.set("custom_colors/font_color",waiting_confirmation_color)

	network.connect("player_list_changed", self, "_on_player_list_changed")
	# If we are in the server, connect to the event that will deal with player despawning
	if (get_tree().is_network_server()):
		network.connect("player_removed", self, "_on_player_removed")
func initialize_op_data(player_id: int):
	var op_p_display_base
	if player_id == 1:
		op_p_display_base = $character_windows/char1/info/VBoxContainer/VBoxContainer/GridContainer/element
	else:
		op_p_display_base = $character_windows/char2/info/VBoxContainer/VBoxContainer/GridContainer/element
	# generate operation probability value display
	var base_display_element = op_p_display_base.get_node("hbox")
	for op_index in global.OP_ID.keys():
		var new_display_element = base_display_element.duplicate()
		var bar = new_display_element.get_node("centering/probability_display")
		var sprite = new_display_element.get_node("op")
		var atlas = AtlasTexture.new()
		atlas.set_atlas(global.sprite_sheet_operations)
		atlas.set_region(Rect2(64*(op_index-1), 0, 64, 64))

		sprite.texture = atlas
		new_display_element.set_name("operation"+str(op_index))
		
		op_p_display_base.add_child(new_display_element)
		bar.set_new_value(0)
		
	#we don't show void operation...
	base_display_element.visible = false

func change_screen_data(char_selected_id: int, player: int):
	
	var character = global.char_data[char_selected_id]

	#the client/server is considered as the player 1 (on the left)
	if player == 1:
		p1_data["incantation_node"].visible = true
		p1_data["character_ID"] = char_selected_id
		#Modifier le label du nom
		p1_data["char_name_label"].set_text(character.get_name())
		
		#Et son ic√¥ne Ì†ΩÌ∏≥Ì†ΩÌ∏≥Ì†ΩÌ∏≥Ì†ΩÌ∏≥Ì†Ω
		p1_data["character_icon"].set_texture(character.get_icon_texture())
		p1_data["character_icon"].visible = true
		#Et afficher la description
		#p1_data["character_lore"].set_text(character.get_descr())
		
		#Et les informations de jeu du personnage
		p1_data["character_descr"].set_text(character.get_info())

		#et modifier les barres de caract√©ristiques
		p1_data["carac_nodes"]["diff"]["bar"].set_new_value(character.get_estimated_diff())
		p1_data["carac_nodes"]["hp"]["bar"].set_new_value(character.get_base_hp())
		p1_data["carac_nodes"]["backlash"]["bar"].set_new_value(character.get_malus_level())

		p1_data["incantation_node"].update_operations(character.get_base_pattern())
		p1_data["op_data"].visible = true
		
		var probabilities: Dictionary = character.get_operation_preference()
		print("new probabilities: \n" +str(probabilities))
		var max_prob_value = 0
		var key_list = probabilities.keys()
		
		#updating probability values
		for i in range(len(probabilities)):
			var key = key_list[i]
			var new_value = probabilities[key]
			var bar = p1_data["op_data"].get_node("element")\
							.get_node("operation"+str(key))\
							.get_node("centering/probability_display")
			bar.set_new_value(new_value)
			if new_value > max_prob_value:
				max_prob_value = new_value
				
		#updating bar max values 
		for i in range(len(probabilities)):
			var key = key_list[i]
			var new_value = probabilities[key]
			var bar = p1_data["op_data"].get_node("element")\
							.get_node("operation"+str(key))\
							.get_node("centering/probability_display")
			bar.set_max(max_prob_value)

		#then order them by decrescent order
		for i in range(len(probabilities)-2,-1,-1):

			var key = key_list[i]
			var hbox_node = p1_data["op_data"].get_node("element")\
											.get_child(i)
			var bar = hbox_node.get_node("centering/probability_display")
			var new_p_value = bar.get_current_value()
			#tri par ordre d√©croissant (par insertion)
			var j = i

			#looking for the new index j
			while j < len(probabilities) - 1 and \
			p1_data["op_data"].get_node("element")\
							.get_child(j+1)\
							.get_node("centering/probability_display")\
							.get_current_value() > new_p_value :
				j += 1
			print("new index: " + str(j))
			p1_data["op_data"].get_node("element")\
							.move_child(hbox_node, j)

	else:
		p2_data["incantation_node"].visible = true
		p2_data["character_ID"] = char_selected_id
		p2_data["char_name_label"].set_text(character.get_name())
		p2_data["character_icon"].set_texture(character.get_icon_texture())
		p2_data["character_icon"].visible = true
		p2_data["character_descr"].set_text(character.get_info())
		p2_data["carac_nodes"]["diff"]["bar"].set_new_value(character.get_estimated_diff())
		p2_data["carac_nodes"]["hp"]["bar"].set_new_value(character.get_base_hp())
		p2_data["carac_nodes"]["backlash"]["bar"].set_new_value(character.get_malus_level())
		p2_data["incantation_node"].update_operations(character.get_base_pattern())
		
		p2_data["op_data"].visible = true
		var probabilities: Dictionary = character.get_operation_preference()
		print("new probabilities: \n" +str(probabilities))
		var max_prob_value = 0
		var key_list = probabilities.keys()
		#updating probability values
		for i in range(len(probabilities)):
			var key = key_list[i]
			var new_value = probabilities[key]
			var bar = p2_data["op_data"].get_node("element")\
							.get_node("operation"+str(key))\
							.get_node("centering/probability_display")
			bar.set_new_value(new_value)
			if new_value > max_prob_value:
				max_prob_value = new_value

		#updating bar max values values
		for i in range(len(probabilities)):
			var key = key_list[i]
			var new_value = probabilities[key]
			var bar = p2_data["op_data"].get_node("element")\
							.get_node("operation"+str(key))\
							.get_node("centering/probability_display")
			bar.set_max(max_prob_value)
			
		#then order them by decrescent order
		for i in range(len(probabilities)-2,-1,-1):

			var key = key_list[i]
			var hbox_node = p2_data["op_data"].get_node("element")\
											.get_child(i)
			var bar = hbox_node.get_node("centering/probability_display")
			var new_p_value = bar.get_current_value()
			#tri par ordre d√©croissant (par insertion)
			var j = i

			#looking for the new index j
			while j < len(probabilities) - 1 and \
			p2_data["op_data"].get_node("element")\
							.get_child(j+1)\
							.get_node("centering/probability_display")\
							.get_current_value() > new_p_value :
				j += 1
			print("new index: " + str(j))
			p2_data["op_data"].get_node("element")\
							.move_child(hbox_node, j)

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
	print("Client id " + str(get_tree().get_rpc_sender_id())+" : Char selection cancel for player " + str(net_id))
	
	Gamestate.player_info["character_validated"] = false
	Gamestate.player_info["id_character_selected"] = -1
	
	add_op_button.disabled = true
	remove_op_button.disabled = true
	if net_id == 1:
		p1_data["incantation_node"].visible = false
		p1_data["character_ID"] = -1
		p1_data["character_icon"].visible = false
		p1_data["op_data"].visible = false
		p1_data["carac_nodes"]["diff"]["bar"].set_new_value(0)
		p1_data["carac_nodes"]["hp"]["bar"].set_new_value(0)
		p1_data["carac_nodes"]["backlash"]["bar"].set_new_value(0)
		p1_data["character_descr"].set_text("")
	else:
		p2_data["incantation_node"].visible = false
		p2_data["character_ID"] = -1
		p2_data["character_icon"].visible = false
		p2_data["op_data"].visible = false
		p2_data["carac_nodes"]["diff"]["bar"].set_new_value(0)
		p2_data["carac_nodes"]["hp"]["bar"].set_new_value(0)
		p2_data["carac_nodes"]["backlash"]["bar"].set_new_value(0)
		p2_data["character_descr"].set_text("")

	if net_id == Gamestate.player_info["net_id"]:
		$HUD/PanelPlayerList/lblLocalPlayer.set("custom_colors/font_color",waiting_confirmation_color)
	else:
		$HUD/PanelPlayerList/boxList.get_node("client"+str(net_id)).set("custom_colors/font_color",waiting_confirmation_color)
		
remotesync func validate_choice(net_id):
	var who = get_tree().get_rpc_sender_id()
	Gamestate.player_info["character_validated"] = true
	
	if get_tree().is_network_server():
		network.players[who]["character_validated"] = true
		
		#if the two players are ready, then the game may start.
		if is_everyone_ready() and len(network.players) > 1:
			leave_scene("res://multiplayer/GameFieldMulti.tscn")
	
	# Visual interaction to show player is ready?
	# if the func is called by this client, then 
	# we change local player label color
	if net_id == Gamestate.player_info["net_id"]:
		$HUD/PanelPlayerList/lblLocalPlayer.set("custom_colors/font_color",confirmed_color)
	else:
		$HUD/PanelPlayerList/boxList.get_node("client"+str(net_id)).set("custom_colors/font_color",confirmed_color)
		pass
func is_everyone_ready():
	for id in network.players:
		if not network.players[id]["id_character_selected"]:
			return false
	return true
	
func _on_return_button_down():
	global.game_mode = 0
	get_tree().set_network_peer(null)
	leave_scene("res://scenes/titlescreen/title.tscn")

func _on_characters_item_selected(index):
	# when a player selects a character, he musts tells the
	# server to show it to the other
	print("Case cliqu√©e: " + str(index))
	#if you validate your choice, you can't change the character.
	if not Gamestate.player_info["character_validated"]:
		var char_selected_id = association[index]
		rpc("character_selection", char_selected_id, Gamestate.player_info["net_id"])

func _on_play_button_down():
	print("Validation id client " + str(Gamestate.player_info["net_id"]))
	rpc("validate_choice", Gamestate.player_info["net_id"])


func _on_cancel_choice_button_down():
	var who = get_tree().get_rpc_sender_id()
	print("Annulation choix par id client " + str(Gamestate.player_info["net_id"]))
	if get_tree().is_network_server():
		network.players[1]["character_validated"] = false
		network.players[1]["id_character_selected"] = -1
	
	rpc("clear_selection", Gamestate.player_info["net_id"])
	
func leave_scene(dest: String):
	scene_transition.play()
	yield(scene_transition,"transition_finished")
	get_tree().change_scene(dest)
	
func _on_add_op_button_down():
	var current_list = p1_data["incantation_node"].get_operation_pattern()
	if len(current_list) < 8:
		current_list.append([2,3])
	p1_data["incantation_node"].update_operations(current_list)


func _on_remove_op_button_down():
	var current_list = p1_data["incantation_node"].get_operation_pattern()
	if len(current_list) > 3:
		current_list.pop_back()
	p1_data["incantation_node"].update_operations(current_list)

func _on_player_list_changed():
	# First remove all children from the boxList widget
	for c in $HUD/PanelPlayerList/boxList.get_children():
		c.queue_free()
	
	# Now iterate through the player list creating a new entry into the boxList
	for p in network.players:
		if (p != Gamestate.player_info["net_id"]):
			var nlabel = Label.new()
			nlabel.name = "client"+str(network.players[p]["net_id"])
			nlabel.text = network.players[p]["pseudo"]
			nlabel.set("custom_colors/font_color",waiting_confirmation_color)
			$HUD/PanelPlayerList/boxList.add_child(nlabel)
			
			
