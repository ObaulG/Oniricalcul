extends Control


class_name StatDisplay


onready var bar = $bar
onready var value_label = $value
onready var tween = $Tween

export(bool) var reverse_gradient
export(float) var current_value

func _ready():
	current_value = 0
	reverse_gradient = false
	set_new_value(0)
	
func set_min(value):
	bar.min_value = value
	
func set_max(value):
	bar.max_value = value

	
func _process(_delta):
	#updating label
	bar.value = current_value
	update_label(round(bar.value))
	#maybe the pos?
	#then the color
	var progress = current_value / bar.max_value
	if reverse_gradient:
		progress = 1 - progress
	bar.get_material().set_shader_param("progression", progress)
	
func set_new_value(value):
	tween.interpolate_property(self, "current_value", current_value, clamp(value, bar.min_value, bar.max_value), 0.6)
	if not tween.is_active():
		tween.start()
	show()

func get_current_value():
	return current_value
func update_label(value):
	value_label.text = str(value)
