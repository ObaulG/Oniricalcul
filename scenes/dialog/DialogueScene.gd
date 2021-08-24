class_name DialogueScene
extends Control


onready var dialogue_parser := $DialogParser
onready var dialogue_box := $DialogParser/DialogueBox
onready var auto_dialogue_play_timer = $automatic_dialogue_play_timer

func _ready():
	dialogue_parser.load_dialogue(ClassicMode.get_next_dialogue_to_be_played())
	play_line()
	
func play_line():
	dialogue_parser.next_line()

		
func _on_DialogueScene_gui_input(event):
	print(event)
	if event.is_pressed() && !event.is_echo() && event.scancode == KEY_ENTER:
		print("Prochaine réplique")
		play_line()
	
func _on_DialogParser_dialogue_end():
	ClassicMode.next_step()
	var state = ClassicMode.get_state()
	if state == ClassicMode.STATES.PLAYING:
		global.set_game_settings(ClassicMode.get_current_game_settings())
		get_tree().change_scene("res://scenes/main_field_game/maingame.tscn")
	else:
		dialogue_parser.load_dialogue(ClassicMode.get_current_dialogue_to_be_played())


func _on_DialogueBox_message_completed():
	auto_dialogue_play_timer.start()

func _on_automatic_dialogue_play_timer_timeout():
	play_line()
