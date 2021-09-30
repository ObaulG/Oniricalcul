extends Area2D


func _ready():
	pass # Replace with function body.

func transfer_to_enemy(power, type):
	get_parent().attack_enemy(power)

func get_id():
	return -1
