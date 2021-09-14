extends Control

signal resume()
signal save_n_quit()

class_name PauseMenu

onready var bg_rect := $ColorRect
onready var resume_button := $VBoxContainer/Button
onready var sq_button := $VBoxContainer/Button2


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



func _on_resume_button_down():
	emit_signal("resume")


func _on_savequit_button_down():
	emit_signal("save_n_quit")

func set_cliquable_buttons(b = true):
	resume_button.disabled = not b
	sq_button.disabled = not b
