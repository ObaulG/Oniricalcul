extends Control

onready var panel = $Panel
onready var power_label = $Panel/power
onready var time_label = $Panel/time_left
onready var hp_display = $Panel/StatDisplay

func _ready():
	pass # Replace with function body.

func set_id(n):
	$Panel/meteor_id.text = str(n)
	
func update_power(n):
	power_label.text = str(n)
	
func update_hp(n):
	hp_display.set_new_value(n)
	
func update_hp_max(n):
	hp_display.set_max_value(n)
	

