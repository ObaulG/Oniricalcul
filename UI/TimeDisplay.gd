extends Control

onready var time_bar = $VBoxContainer/time_left_bar
onready var label = $VBoxContainer/Label
func _ready():
	time_bar.min_value = 0

func set_max(value):
	time_bar.max_value = value
	
func _process(_delta):
	pass
	#time_bar.global_rotation = 0
	
func update_time(value):
	time_bar.texture_progress = global.bar_green
	if value < time_bar.max_value * 0.5:
		time_bar.texture_progress = global.bar_yellow
	if value < time_bar.max_value * 0.15:
		time_bar.texture_progress = global.bar_red
	time_bar.value = value
	label.text = str(stepify(value,0.01))
	show()
