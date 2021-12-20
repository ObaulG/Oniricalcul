extends Control

class_name StatDisplay

onready var bar = $bar
onready var value_label = $value
onready var tween = $Tween

export(bool) var reverse_gradient
export(float) var current_value
export(bool) var percent

var displayed_value := 0.0
var displayed_max_value
var displayed_min_value

func _ready():
	current_value = 0
	displayed_value = current_value
	displayed_max_value = bar.max_value
	displayed_min_value = bar.min_value
	set_new_value(0)

func _process(_delta):
	#updating label
	bar.value = displayed_value
	bar.min_value = displayed_min_value
	bar.max_value = displayed_max_value
	
	update_label(round(displayed_value))
	#maybe the pos?
	
	var progress = (bar.max_value - displayed_value) / max(0.01,(bar.max_value - bar.min_value))
	#then the color
	bar.get_material().set_shader_param("reverse", reverse_gradient)
	bar.get_material().set_shader_param("progression", progress)

func set_min_value(value):
	bar.min_value = value
	tween.interpolate_property(self, "displayed_min_value", displayed_min_value, value, 0.75)
	if not tween.is_active():
		tween.start()
	show()
	
func set_max_value(value):
	bar.max_value = value
	tween.interpolate_property(self, "displayed_max_value", displayed_max_value, value, 0.75)
	if not tween.is_active():
		tween.start()
	show()
	
func set_reverse_gradient(b: bool):
	reverse_gradient = b

func set_percent_mode(b: bool):
	percent = b
	
func set_new_value(value):
	current_value = value
	tween.interpolate_property(self, "displayed_value", displayed_value, clamp(value, bar.min_value, bar.max_value), 0.75)
	if not tween.is_active():
		tween.start()
	show()

func get_current_value():
	return current_value
	
func update_label(value):
	if percent:
		value_label.text = str(stepify((100*value)/max(1,bar.max_value), 0.1)) + " %"
	else:
		value_label.text = str(value)


func _on_BaseDomainData_hp_value_changed(_gid, new_value):
	set_new_value(new_value)
