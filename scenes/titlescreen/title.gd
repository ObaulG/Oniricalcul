extends CanvasLayer


onready var fast_game_button = $VBoxContainer/buttons_container/list/fast_game_button
onready var classic_game_button = $VBoxContainer/buttons_container/list/classic_game_button
onready var history_game_button = $VBoxContainer/buttons_container/list/history_mode_button
onready var quit_button = $VBoxContainer/buttons_container/list/quit_button
onready var options_button = $VBoxContainer/buttons_container/list/options_button

onready var meteor_timer = $meteor_timer
onready var bg_music_timer = $bgmusic_timer

onready var scene_transition = $SceneTransitionRect

func _ready():
	global.game_mode = 0
	get_tree().paused = false

	scene_transition.visible = true
	scene_transition.play(true)

func _on_play_button_down(extra_arg_0: int):
	global.game_mode = extra_arg_0
	var new_scene_path: String
	match extra_arg_0:
		1:
			new_scene_path = "res://scenes/charselect/CharacterSelection.tscn"
		2:
			ClassicMode.reset_game()
			new_scene_path = "res://scenes/dialog/DialogueScene.tscn"
		3:
			pass
		4:
			new_scene_path = "res://multiplayer/Onirilobby.tscn"
	scene_transition.change_scene(new_scene_path)

func _on_options_button_down():
	pass # Replace with function body.


func _on_quit_button_down():
	get_tree().quit()

func _on_bgmusic_timer_timeout():
	SoundPlayer.play_bg_music("titlescreen")
