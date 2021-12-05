extends Object

class_name Operation

var result
var diff: int
var type: int
var subtype

func _init(diff, type, st = -1):
	result = null
	self.type = type
	self.diff = diff
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

func get_potential() -> int:
	return global.get_op_power(type,diff)
	
func to_string() -> String:
	return "Operation"
