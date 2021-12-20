extends VSlider

onready var panel = $Panel
onready var title_label = $Panel/VBoxContainer/CenterContainer/title_label
onready var value_label = $Panel/VBoxContainer/CenterContainer2/value_label

# Called when the node enters the scene tree for the first time.
func _ready():
	panel.visible = false

func get_value():
	return value

func _on_VSlider_mouse_entered():
	panel.visible = true
	print("mouse in slider ")

func _on_VSlider_mouse_exited():
	panel.visible = false


func _on_VSlider_value_changed(value):
	value_label.text = str(value)
