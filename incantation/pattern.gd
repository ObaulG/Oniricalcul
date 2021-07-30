extends Object

const MAX_OP = 8

class_name Pattern

var operations_list: Array
var index: int
var scaling_coeff: float
var power: ReliquatNumber


func _init(L = [], scaling_value = 5):
	operations_list = L
	index = 0
	power = ReliquatNumber.new(0)
	scaling_coeff = 1 + scaling_value/100
	power_evaluation()

func power_evaluation():
	var total = 0
	for i in range(len(operations_list)):
		var type = operations_list[i][0]
		var diff = operations_list[i][1]
		total += global.get_op_power(type, diff) * pow(scaling_coeff, i)
	power.set_value(total)
	
func add_to(operation, i):
	operations_list.insert(i, operation)
	power_evaluation()
	
func append(operation):
	operations_list.append(operation)
	power_evaluation()
	
func remove(i):
	operations_list.remove(i)
	index = index % len(operations_list)
	power_evaluation()
	
func get_current_op() -> Array:
	return operations_list[index]
	
func reverse_gear(n = 1):
	index = max(0, index - n)
	
func next() -> bool:
	index = (index + 1) % len(operations_list)
	return index == 0
	
func get_index() -> int:
	return index
	
func get_len() -> int:
	return len(operations_list)
	
func get_operation(i: int):
	return operations_list[i]

func get_list() -> Array:
	return operations_list.duplicate()
	
func get_power(bonus = 0.0, for_display_only = false) -> float:
	if for_display_only:
		return power.get_value()
	else:
		return power.apply(bonus)
	
func set_coeff(value: float):
	scaling_coeff = value
	
func set_index(i: int):
	index = i
	
func set_operations_list(L: Array):
	operations_list = L
	power_evaluation()
	if index < len(operations_list):
		index = 0
	
