extends Control


onready var operation_display = $operation_display
onready var label_answer = $operation_answer


# Called when the node enters the scene tree for the first time.
func _ready():
	operation_display.text = "..."
	clear_answer()

func _on_InputHandler_write_digit(d):
	label_answer.text += str(d)

func _on_InputHandler_delete_digit():
	label_answer.text = label_answer.text.substr(0, len(label_answer.text)-1)

func change_operation_display(op: Operation):
	operation_display.text = op.get_str_show()
	clear_answer()
	
func clear_answer():
	label_answer.text = ""

func get_answer() -> String:
	return label_answer.text
	
func set_operation_display(s: String):
	operation_display.text = s
	
func _on_spellbook_operation_to_display_has_changed(new_op):
	change_operation_display(new_op)


func _on_InputHandler_check_answer_command():
	clear_answer()
