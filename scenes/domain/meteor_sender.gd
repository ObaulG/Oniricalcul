extends KinematicBody2D

signal magic_projectile_inside(power, type)

func _ready():
	pass # Replace with function body.

func transfer_to_enemy(power, type):
	print("magic projectile sent signal to meteor sender")
	emit_signal("magic_projectile_inside", power, type)

func get_id():
	return -1
