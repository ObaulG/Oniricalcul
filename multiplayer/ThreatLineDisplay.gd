extends Control

class_name ThreatLineDisplay

onready var panel = $Panel
onready var power_label = $Panel/power
onready var time_label = $Panel/time_left
onready var hp_display = $Panel/StatDisplay
onready var meteor_id = $Panel/meteor_id
onready var timer = $Timer

func _ready():
	print("OMG")

func _process(_delta):
	update_delay_display()
	
func start(time):
	timer.start(time)
	
func set_id(n):
	meteor_id.text = str(n)
	
func update_power(n):
	power_label.text = str(n)
	
func update_hp(n):
	hp_display.set_new_value(n)
	
func update_hp_max(n):
	hp_display.set_max_value(n)
	
func update_delay_display():
	time_label.text = str(stepify(timer.time_left, 0.01))

func get_id():
	return int(meteor_id.text)

func _on_Timer_timeout():
	queue_free()
