extends Object

class_name Operation

enum ANSWER_TYPE {
	SINGLE_NUMBER = 1,
	MATH_EXPR = 2,
	MULTIPLE_NUMBERS = 3,
	QCM = 4,
}

var result
var diff: int
var type: int
var subtype

func _init(hardness, t, st = -1):
	result = null
	self.type = t
	self.diff = hardness
	subtype = st

func is_result(value) -> bool:
	return str(result) == str(value)
	
func get_result():
	return result

func get_type():
	return type
	
func get_subtype():
	return subtype
	
func get_diff():
	return diff

func get_pattern_element() -> Array:
	return [type, diff]
	
func get_potential() -> int:
	return global.get_op_power(type,diff)
	
func _to_string() -> String:
	return "Operation"
