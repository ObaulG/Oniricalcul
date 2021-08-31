extends Node

enum SELECTION_STATE{ZERO, ONE, TWO}

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

var anim_player 
func _ready():
	anim_player = $SceneTransitionRect/AnimationPlayer
	anim_player.play_backwards("fade")
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
	diff_label = $vbox_info/VBoxContainer/hardness_label
	diff_slider = $vbox_info/VBoxContainer/CenterContainer2/hardness
	character_list = $vbox_info/VBoxContainer/CenterContainer/characters
	
	two_character_selection = false
	selection_state = SELECTION_STATE.ZERO
	match global.game_mode:
		1:
			two_character_selection = true
		2:
			two_character_selection = true
		3:
			pass
		4:
			pass

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
	
func change_screen_data(player: int, char_selected_id: int):
	var character = global.char_data[char_selected_id]
	#useless now
	#var char_dico = global.characters[id]
	
	if player == 1:
		
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
			
func _on_return_button_down():
	global.game_mode = 0
	leave_scene("res://scenes/titlescreen/title.tscn")


func _on_hardness_value_changed(value):
	#value is float
	match(int(value)):
		0:
			diff_label.text = "Tr√®s facile"
		1:
			diff_label.text = "Facile"
		2: 
			diff_label.text = "Moyen"
		3:
			diff_label.text = "Difficile"
		4:
			diff_label.text = "Tr√®s difficile"
		5:
			diff_label.text = "Extr√™me"
		_:
			diff_label.text = "???"


func _on_characters_item_selected(index):
	print("Case cliqu√©e: " + str(index))
	var char_selected_id = association[index]
	
	var id_player = 1
	match selection_state:
		SELECTION_STATE.ZERO:
			id_player = 1
			selection_state += 1
		SELECTION_STATE.ONE:
			id_player = 2
			selection_state += 1
		SELECTION_STATE.TWO:
			id_player = 2
	character_list.unselect_all()
	change_screen_data(id_player, char_selected_id)


func _on_play_button_down():
	var can_play = false
	match selection_state:
		SELECTION_STATE.ZERO:
			print("Aucun personnage s√©lectionn√© !")
			#Pop-up ("no character selected!!!")
		SELECTION_STATE.ONE:
			can_play = !two_character_selection
		SELECTION_STATE.TWO:
			can_play = two_character_selection
			
	if can_play:
		global.character = p1_data["character_ID"]
		global.enemy_character = p2_data["character_ID"]
		global.diff = int(diff_slider.value)
		leave_scene("res://scenes/main_field_game/maingame.tscn")


func _on_cancel_choice_button_down():
	selection_state = SELECTION_STATE.ZERO
	p1_data["character_ID"] = -1
	p1_data["character_icon"].visible = false
	p2_data["character_ID"] = -1
	p2_data["character_icon"].visible = false
	p1_data["op_data"].visible = false
	p2_data["op_data"].visible = false
	p1_data["carac_nodes"]["diff"]["bar"].set_new_value(0)
	p1_data["carac_nodes"]["hp"]["bar"].set_new_value(0)
	p1_data["carac_nodes"]["backlash"]["bar"].set_new_value(0)
	p2_data["carac_nodes"]["diff"]["bar"].set_new_value(0)
	p2_data["carac_nodes"]["hp"]["bar"].set_new_value(0)
	p2_data["carac_nodes"]["backlash"]["bar"].set_new_value(0)
	p1_data["character_descr"].set_text("")
	p2_data["character_descr"].set_text("")
	
func leave_scene(dest: String):
	anim_player.play("fade")
	yield(anim_player,"animation_finished")
	get_tree().change_scene(dest)
	
func _on_add_op_button_down():
	var current_list = p1_data["incantation_node"].get_list()
	if len(current_list) < 8:
		current_list.append([2,3])
	p1_data["incantation_node"].update_operations(current_list)


func _on_remove_op_button_down():
	var current_list = p1_data["incantation_node"].get_list()
	if len(current_list) > 3:
		current_list.pop_back()
	p1_data["incantation_node"].update_operations(current_list)
