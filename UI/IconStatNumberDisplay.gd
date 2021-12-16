extends Control

class_name IconStatNumberDisplay

var texture_length = 32
var min_value: float
var max_value: float

onready var text_rect = $HBoxContainer/CenterContainer/texture
onready var label_value = $HBoxContainer/value_label

func _ready():
	min_value = 0.0
	max_value = 65535.0
	label_value.text = "0"
	
func change_value_displayed(x: float):
	label_value.text = str(clamp(x, min_value, max_value))

func set_min_value(x: float):
	min_value = x
	change_value_displayed(float(label_value.text))
	
func set_max_value(x: float):
	max_value = x
	change_value_displayed(float(label_value.text))
