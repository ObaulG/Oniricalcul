extends Control

class_name CalculZone


var operation: Operation
var answer: String

func _ready():
	pass # Replace with function body.

func get_diff():
	return operation.get_diff()
	
func get_answer():
	return answer
	

