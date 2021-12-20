extends Control

class_name PopUpNotification

enum DISPLAY_POSITION{
	TOP_RIGHT = 1, 
	TOP_LEFT, 
	BOTTOM_LEFT, 
	BOTTOM_RIGHT, 
	FREE
}
var display_time: float
var text: String
var display_type: int

onready var popup_node = $Popup
onready var timer = $Timer
onready var picture = $Popup/TextureRect
onready var display_text = $Popup/RichTextLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func initialize(t, message, d_type = DISPLAY_POSITION.BOTTOM_RIGHT):
	display_time = t
	text = message
	display_text.text = text
	display_type = d_type
	
func _process(delta):
	var time_left = display_time - timer.time_left
	modulate.a = time_left/display_time
	
func display_on_screen():
	timer.start(display_time)
	popup_node.show()
	
func stop_displaying():
	queue_free()
	
func get_display_type():
	return display_type

func set_texture_icon(pict: Texture):
	picture.texture = pict
	

func _on_Timer_timeout():
	queue_free()
