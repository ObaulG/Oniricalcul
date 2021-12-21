extends Control

class_name CharacterDisplay

signal ui_updated()
signal bot_diff_changed(id, new_value)

const confirmed_color = Color(0.11,0.92,0.08)
const unconfirmed_color = Color(0.78,0.75,0.76)
const no_player_color = Color(0.24,0.28,0.27)

export(bool) var horizontal_reverse: bool = false
export(int) var id_character_selected
export(bool) var validated = false
export(bool) var bot = false

var id_player: int

onready var cr_info_bg = $cr_bg

onready var hbox_node = $hbox
onready var bot_diff_slider = $bot_diff_label

# One part inside the hbox
onready var char_icon = $hbox/vbox/char_icon
onready var player_name = $hbox/vbox/name

#The other part
onready var color_rect = $hbox/ColorRect

onready var next_char_button = $next_char_button
onready var previous_char_button = $previous_char_button

func _ready():
	id_character_selected = -1
	id_player = -1

	validated = false
	bot = false

	bot_diff_slider.visible = false
	next_char_button.visible = false
	previous_char_button.visible = false
	
func remove_player():
	set_player_name("???")
	cancel_validation()
	id_player = -1
	cr_info_bg.color = no_player_color
	
func add_player(name: String, id: int):
	set_player_name(name)
	id_player = id
	cr_info_bg.color = unconfirmed_color
	
func change_screen_data(id: int):
	var character = global.char_data[id]
	char_icon.set_texture(character.get_icon_texture())
	char_icon.visible = true
	emit_signal("ui_updated")

func validate_ui():
	#when validated, we change the color of the rect
	cr_info_bg.color = confirmed_color
	
func cancel_ui():
	cr_info_bg.color = unconfirmed_color
	
func clear_selection():
	char_icon.texture = global.get_resized_ImageTexture(global.unknown, 128, 128)
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
	
func has_player() -> bool:
	return player_name != "???"
	
func is_bot() -> bool:
	return bot
	
func get_character_selected():
	return id_character_selected

func get_validated():
	return validated
	
func get_id_player() -> int:
	return id_player
	
func get_player_name() -> String:
	return player_name.text
	
func get_bot_hardness() -> int:
	return bot_diff_slider.get_value()
	
func set_player_name(s: String):
	player_name.text = s
	
func set_bot(b: bool):
	bot = b
	if get_tree().is_network_server():
		if bot:
			bot_diff_slider.visible = true
			bot_diff_slider.editable = true
			next_char_button.show()
			next_char_button.disabled = false
			previous_char_button.show()
			previous_char_button.disabled = false
		else:
			bot_diff_slider.visible = false
			bot_diff_slider.editable = false
			next_char_button.hide()
			next_char_button.disabled = true
			previous_char_button.hide()
			previous_char_button.disabled = true
	
func set_bot_diff(new_value):
	bot_diff_slider.value = new_value
	
func _on_bot_diff_label_value_changed(value):
	emit_signal("bot_diff_changed", id_player, value)

func _on_bot_diff_label_mouse_entered():
	print("mouse in vslider in character display")


func _on_next_char_button_button_down():
	print("next button clicked")
	select_character(global.id_next_char(id_character_selected))

func _on_previous_char_button_button_down():
	select_character(global.id_prev_char(id_character_selected))
