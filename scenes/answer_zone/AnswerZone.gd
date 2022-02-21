extends Control

enum ACTIONS {
	WRITE_DIGIT,
	DELETE_DIGIT,
	CLEAR_ANSWER,
	CHANGE_SIGN,
	SEND
}

enum ANSWER_TYPE {
	NUMBER = 1,
	MATH_EXPR,
	FRACTION,
	QCM,
}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func display_new_operation(operation: Operation):
	var p_el = operation.get_pattern_element()
	var type = p_el[0]
	var diff = p_el[1] 
	
	var display_type = global.get_op_answer_type(type)
	change_display_node(display_type)
	match display_type:
		1:
			pass
		2:
			pass
		3:
			pass
		4:
			pass
			
func change_display_node(display_type: int):
	match display_type:
		1:
			pass
		2:
			pass
		3:
			pass
		4:
			pass
