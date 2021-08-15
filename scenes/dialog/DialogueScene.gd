class_name DialogueScene
extends Control

onready var dialogue_box := $DialogueBox
onready var dialogue_parser := $DialogParser

func _ready():
	dialogue_parser.load_dialogue(global.current_dialog)



func play_line():
	dialogue_parser.next_line()

		
func _on_DialogueScene_gui_input(event):
	pass # Replace with function body.
	



func _on_DialogueBox_gui_input(event):
	pass # Replace with function body.
