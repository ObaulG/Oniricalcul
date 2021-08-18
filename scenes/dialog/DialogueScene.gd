class_name DialogueScene
extends Control

onready var dialogue_box := $DialogueBox
onready var dialogue_parser := $DialogParser

func _ready():
	dialogue_parser.load_dialogue(ClassicMode.get_current_dialogue_to_be_played())

func play_line():
	dialogue_parser.next_line()

		
func _on_DialogueScene_gui_input(event):
	pass # Replace with function body.
	

func _on_DialogueBox_gui_input(event):
	pass # Replace with function body.


func _on_DialogParser_dialogue_end():
	ClassicMode.next_step()
	var state = ClassicMode.get_state()
	if state == ClassicMode.STATES.PLAYING:
		global.set_game_settings(ClassicMode.get_current_game_settings())
		get_tree().change_scene("res://scenes/main_field_game/maingame.tscn")
	else:
		dialogue_parser.load_dialogue(ClassicMode.get_current_dialogue_to_be_played())
