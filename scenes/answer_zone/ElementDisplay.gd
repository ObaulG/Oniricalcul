extends Control

class_name ElementDisplay


enum ELEMENT_TYPE{
	CALCUL,
	MATH_EXPR,
	FRACTION,
	TEXT
}


var node_to_display

onready var text_rt = $text
onready var calcul_node = $calcul
onready var fractions_list = $hbox_frac


func _ready():
	pass # Replace with function body.


func hide_all():
	text_rt.hide()
	calcul_node.hide()
	for c in fractions_list.get_children():
		c.hide()
	
func display_new_element():
	pass
	
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

