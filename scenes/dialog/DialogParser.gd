extends Node

signal change_background(name)
signal dialogue_end()
var index
var current_dialog
var dialog_end_actions

onready var dialogue_box := $DialogueBox
onready var main_char_left := $main_char_1
onready var main_char_right:= $main_char_2
onready var talking_char_label := $name/RichTextLabel
func _ready():
	current_dialog = []
	index = -1


func load_dialogue(name: String):
	var data = global.get_dialog_tree(name)
	current_dialog = data["tree"]
	dialog_end_actions = data["dialog_end_actions"]
	emit_signal("change_background", data["background"])
	
func next_line():
	if not is_last_line():
		var data = next_line()
		if data != {}:
			var starting_actions = data["starting_actions"]
			var dialog_id = data["string_id"]
			var char_id = int(data["char_id"])
			var starting_char_expression = data["char_expression"]
		
			parse_starting_actions(starting_actions)
			talking_char_label.set_text(global.get_char_name(int(char_id)))
			dialogue_box.update_message(dialog_id)
			index += 1

	else:
		emit_signal("dialogue_end")
		return {}
		
func previous_line():
	if not is_first_line():
		index -= 1
		return current_dialog[index]
	else:
		return {}
	
func parse_starting_actions(dict):
	for action in dict.keys():
		var value = dict[action]
		match action:
			"set_left_main_char":
				pass
			"set_right_main_char":
				pass
				
func end_actions():
	for action in dialog_end_actions.keys():
		var value = dialog_end_actions[action]
		match action:
			"play_game":
				var player_char_id = value["player_char_id"]
				var cpu_char_id = value["cpu_char_id"]
				var hardness = int(value["hardness"])
				return [player_char_id, cpu_char_id, hardness]

func is_first_line():
	return index == 0
	
func is_last_line():
	return index < get_dialog_size() - 1
	
func get_dialog_size() -> int:
	return len(current_dialog)

func get_end_actions():
	return dialog_end_actions
