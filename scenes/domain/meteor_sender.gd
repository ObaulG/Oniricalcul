extends Area2D

signal magic_projectile_inside(power, type)

func _ready():
	pass # Replace with function body.

func transfer_to_enemy(power, type):
	emit_signal("magic_projectile_inside", power, type)

func get_id():
	return -1
