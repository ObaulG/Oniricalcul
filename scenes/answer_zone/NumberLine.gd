extends Control

const MAX_SIZE = 12

export(Font) var font

class_name NumberLine

enum DISPLAY_TYPE{
	TEXTURE,
	STRING,
}

onready var lb_number = $number

func _ready():
	pass # Replace with function body.

func update_number(n: int):
	lb_number.text = str(n)

