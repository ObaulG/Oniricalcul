extends Control


class_name StatDisplay


onready var bar = $bar
onready var value_label = $value
onready var tween = $Tween

export(bool) var reverse_gradient
export(float) var current_value

var displayed_value
func _ready():
	current_value = 0
	displayed_value = current_value
	set_new_value(0)
	
func set_min(value):
	bar.min_value = value
	
func set_max(value):
	bar.max_value = value

func set_reverse_gradient(b: bool):
	reverse_gradient = b

func _process(_delta):
	#updating label
	bar.value = displayed_value
	update_label(round(bar.value))
	#maybe the pos?
	#then the color
	var progress = displayed_value / bar.max_value
	bar.get_material().set_shader_param("reverse", reverse_gradient)
	bar.get_material().set_shader_param("progression", progress)
	
func set_new_value(value):
	current_value = value
	tween.interpolate_property(self, "displayed_value", displayed_value, clamp(value, bar.min_value, bar.max_value), 0.6)
	if not tween.is_active():
		tween.start()
	show()

func get_current_value():
	return current_value
	
func update_label(value):
	value_label.text = str(value)
