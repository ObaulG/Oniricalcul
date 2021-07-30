extends Node2D


var list_op
var op1
var op2
var op3

# Called when the node enters the scene tree for the first time.
func _ready():
	list_op = $Incantation_Operations
	op1 = $operation
	op2 = $operation2
	op3 = $operation3
	
	op1.change_operation(1,1)
	op1.set_display_type(Operation_Display.DISPLAY_TYPE.BUYING)
	op2.change_operation(2,2)
	op2.set_display_type(Operation_Display.DISPLAY_TYPE.BUYING)
	op3.change_operation(3,3)
	op3.set_display_type(Operation_Display.DISPLAY_TYPE.BUYING)
