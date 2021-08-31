extends CanvasLayer


var fast_game_button
var classic_game_button
var history_game_button
var quit_button
var options_button

var meteor_timer
var bg_music_timer

var anim_player
func _ready():
	anim_player = $SceneTransitionRect/AnimationPlayer
	anim_player.play_backwards("fade")
	fast_game_button = $VBoxContainer/buttons_container/list/fast_game_button
	classic_game_button = $VBoxContainer/buttons_container/list/classic_game_button
	history_game_button = $VBoxContainer/buttons_container/list/history_mode_button
	quit_button = $VBoxContainer/buttons_container/list/quit_button
	options_button = $VBoxContainer/buttons_container/list/options_button

	meteor_timer = $meteor_timer
	bg_music_timer = $bgmusic_timer
	global.load_game()
	
	
	
func _on_play_button_down(extra_arg_0: int):
	global.game_mode = extra_arg_0
	anim_player.play("fade")
	yield(anim_player, "animation_finished")
	match extra_arg_0:
		1:
			get_tree().change_scene("res://scenes/charselect/CharacterSelection.tscn")
		2:
			ClassicMode.reset_game()
			get_tree().change_scene("res://scenes/dialog/DialogueScene.tscn")
		3:
			pass
		4:
			pass


func _on_options_button_down():
	pass # Replace with function body.


func _on_quit_button_down():
	get_tree().quit()


func _on_bgmusic_timer_timeout():
	SoundPlayer.play_bg_music("titlescreen")
