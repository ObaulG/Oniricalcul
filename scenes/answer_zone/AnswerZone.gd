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
	NONE
}

var node_to_display = null
onready var calcul_node = $CalculAnswer
onready var frac_node = $FractionAnswer

func _ready():
	pass # Replace with function body.

func do_action(action):
	match action:
		ACTIONS.WRITE_DIGIT:
			pass
		ACTIONS.DELETE_DIGIT:
			pass
		ACTIONS.CLEAR_ANSWER:
			pass
		ACTIONS.CHANGE_SIGN:
			pass
		ACTIONS.SEND:
			pass

func hide_all():
	calcul_node.visible = false
	frac_node.visible = false
	
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
	hide_all()
	match display_type:
		1:
			calcul_node.visible = true
		2:
			pass
		3:
			frac_node.visible = true
		4:
			pass
