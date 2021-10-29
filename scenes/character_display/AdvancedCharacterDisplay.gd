extends Node

class_name AdvancedCharacterDisplay

signal ui_updated()

const confirmed_color = Color(0.11,0.92,0.08)
const unconfirmed_color = Color(0.78,0.75,0.76)
const no_player_color = Color(0.24,0.28,0.27)

export(bool) var horizontal_reverse: bool = false
export(int) var id_character_selected
export(bool) var validated = false

var id_player: int
onready var cr_info_bg = $cr_bg

onready var hbox_node = $hbox
# One part inside the hbox
onready var char_icon = $hbox/vbox/char_icon
onready var player_name = $hbox/vbox/name

#The other part
onready var color_rect = $hbox/ColorRect
# One part inside the hbox
onready var incantation_node = $hbox/vbox/Incantation

#The other part
onready var hp_label = $hbox/info/vbox/hbox/vbox/hp_label
onready var hp_bar = $hbox/info/vbox/hbox/vbox2/hp_display

onready var hardness_label = $hbox/info/vbox/hbox/vbox/hardness_label
onready var hardness_bar = $hbox/info/vbox/hbox/vbox2/hardness_display

onready var char_descr = $hbox/info/vbox/char_descr

onready var backlash_label = $hbox/info/vbox/hbox2/vbox/backlash_label
onready var backlash_bar = $hbox/info/vbox/hbox2/vbox2/backlash_display
onready var backlash_descr = $hbox/info/vbox/backlash_descr

onready var probability_display_grid = $hbox/info/vbox/vbox/gridc
onready var probability_display_list = $hbox/info/vbox/vbox/gridc/op_list
onready var probability_display_element = $hbox/info/vbox/vbox/gridc/op_list/element

func _ready():
	initialize_op_data()
	id_character_selected = -1
	id_player = -1
	validated = false
	cancel_validation()
	cr_info_bg.color = no_player_color
	
func add_player(name: String, id: int):
	set_player_name(name)
	id_player = id
	cr_info_bg.color = unconfirmed_color
	
func remove_player():
	set_player_name("???")
	cancel_validation()
	id_player = -1
	cr_info_bg.color = no_player_color

func initialize_op_data():
	for op_index in global.OP_ID.keys():
		var new_display_element = probability_display_element.duplicate()
		var bar = new_display_element.get_node("centering/probability_display")
		var sprite = new_display_element.get_node("op")
		var atlas = AtlasTexture.new()
		atlas.set_atlas(global.sprite_sheet_operations)
		atlas.set_region(Rect2(64*(op_index-1), 0, 64, 64))

		sprite.texture = atlas
		new_display_element.set_name("operation"+str(op_index))
		
		probability_display_list.add_child(new_display_element)
		bar.set_new_value(0)
		bar.set_percent_mode(true)
		print("Op√©ration ajout√©e")
		print(probability_display_list.get_children())
	#we don't show void operation...
	probability_display_element.visible = false
	
func change_screen_data(id_char: int):
	var character = global.char_data[id_char]
	
	incantation_node.visible = true
	incantation_node.update_operations(character.get_base_pattern())
	
	#Et son ic√¥ne Ì†ΩÌ∏≥Ì†ΩÌ∏≥Ì†ΩÌ∏≥Ì†ΩÌ∏≥Ì†Ω
	char_icon.set_texture(character.get_icon_texture())
	char_icon.visible = true
	#Et afficher la description
	#p1_data["character_lore"].set_text(character.get_descr())
	
	#Et les informations de jeu du personnage
	char_descr.set_text(character.get_info())

	#et modifier les barres de caract√©ristiques
	hardness_bar.set_new_value(character.get_estimated_diff())
	hp_bar.set_new_value(character.get_base_hp())
	backlash_bar.set_new_value(character.get_malus_level())

	probability_display_grid.visible = true
	
	var probabilities: Dictionary = character.get_operation_preference()

	var max_prob_value = 0
	var key_list = probabilities.keys()
	var sum_probs = 0

	print(str(probability_display_list.get_children()))
	#updating bar values 
	for i in range(len(probabilities)):
		var key = key_list[i]
		var new_value = probabilities[key]
		var bar = probability_display_list.get_node("operation"+str(key))\
										  .get_node("centering/probability_display")
										
		sum_probs += new_value
		bar.set_new_value(new_value)
	#then order them by decrescent order
	for i in range(len(probabilities)-2,-1,-1):
		
		var key = key_list[i]
		var hbox= probability_display_list.get_child(i)
		var bar = hbox.get_node("centering/probability_display")
		bar.set_max_value(sum_probs)
		var new_p_value = bar.get_current_value()
		#tri par ordre d√©croissant (par insertion)
		var j = i

		#looking for the new index j
		while j < len(probabilities) - 1 and \
		probability_display_list.get_child(j+1)\
						.get_node("centering/probability_display")\
						.get_current_value() > new_p_value :
			j += 1
		#print("new index: " + str(j))
		probability_display_list.move_child(hbox, j)
	emit_signal("ui_updated")

func validate_ui():
	#when validated, we change the color of the rect
	cr_info_bg.color = confirmed_color
	
func cancel_ui():
	cr_info_bg.color = unconfirmed_color
	
func clear_selection():
	incantation_node.visible = false
	char_icon.texture = global.get_resized_ImageTexture(global.unknown, 256, 256)
	probability_display_grid.visible = false
	hardness_bar.set_new_value(0)
	hp_bar.set_new_value(0)
	backlash_bar.set_new_value(0)
	char_descr.set_text("")
	emit_signal("ui_updated")

func select_character(id: int):
	id_character_selected = id
	change_screen_data(id)
	
func validate_choice():
	validated = true
	validate_ui()
	
func cancel_validation():
	id_character_selected = -1
	validated = false
	clear_selection()
	cancel_ui()
	
func reverse_ui_elements():
	var first_element = hbox_node.get_child(0)
	hbox_node.remove_child(first_element)
	hbox_node.add_child(first_element)
	
func set_player_name(s: String):
	player_name.text = s
	
func get_player_id() -> int:
	return id_player
	
func get_character_selected():
	return id_character_selected

func get_validated():
	return validated
	
