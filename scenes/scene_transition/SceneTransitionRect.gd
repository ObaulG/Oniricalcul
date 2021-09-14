extends ColorRect

class_name SceneTransitionRect

signal transition_finished()

onready var anim_player := $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func play(reverse = false):
	if reverse:
		anim_player.play_backwards("fade")
	else:
		anim_player.play("fade")


func _on_AnimationPlayer_animation_finished(anim_name):
	emit_signal("transition_finished")
	

