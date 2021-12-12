extends Control


onready var operation_display = $operation_display
onready var label_answer = $operation_answer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_InputHandler_write_digit(d):
	label_answer.text += d

func _on_InputHandler_delete_digit():
	label_answer.text = label_answer.text.substr(0, len(label_answer.text)-1)

func change_operation_display(op: Operation):
	operation_display.text = op.to_string()
	
func clear_answer():
	label_answer.text = ""

func get_answer() -> String:
	return label_answer.text
	
func set_operation_display(s: String):
	operation_display.text = s
