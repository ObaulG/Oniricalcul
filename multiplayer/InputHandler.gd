extends Node

#All input logic will be handled here. 
const keypad_numbers = [48,49,50,51,52,53,54,55,56,57]
const numpad_numbers = [KEY_KP_0,KEY_KP_1,KEY_KP_2,KEY_KP_3,KEY_KP_4,KEY_KP_5,KEY_KP_6,KEY_KP_7,KEY_KP_8,KEY_KP_9]
signal check_answer_command()
signal changing_stance_command(new_stance)
signal delete_digit()
signal write_digit(d)
onready var parent = get_parent()


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _input(event):
	if event.is_action("delete_char") && event.is_pressed() && !event.is_echo():
		emit_signal("delete_digit")
	if event.is_action("validate") && event.is_pressed() && !event.is_echo():
		emit_signal("check_answer_command")

	if event.is_action("attack_stance") && event.is_pressed() && !event.is_echo():
		emit_signal("changing_stance_command", 1)
		
	if event.is_action("defense_stance") && event.is_pressed() && !event.is_echo():
		emit_signal("changing_stance_command", 2)
		
	if event.is_action("bonus_stance") && event.is_pressed() && !event.is_echo():
		emit_signal("changing_stance_command", 1)
		
	if event is InputEventKey and event.pressed:
		if event.scancode in keypad_numbers:
			emit_signal("write_digit", keypad_numbers.bsearch(event.scancode))
		elif event.scancode in numpad_numbers:
			emit_signal("write_digit", numpad_numbers.bsearch(event.scancode))


func input_check_answer():
	emit_signal("check_answer_command")
	
func input_stance_change(new_stance):
	emit_signal("input_stance_change", new_stance)
