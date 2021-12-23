extends Object

const MAX_OP = 8

class_name Pattern

signal incantation_has_changed()

#contains arrays of size 2 : [type, diff]
var elements: Array

var index: int
var scaling_coeff: float
var power: ReliquatNumber

func _init(L = [], scaling_value = 5):
	elements = L.duplicate()
	index = 0
	power = ReliquatNumber.new(0)
	scaling_coeff = 1 + scaling_value/100
	power_evaluation()

func power_evaluation():
	var total = 0
	for i in range(len(elements)):
		var type = elements[i][0]
		var diff = elements[i][1]
		print(str([type,diff]))
		print("Potentiel opération numero " + str(i) + ": " + str(global.get_op_power(type, diff)))
		total += global.get_op_power(type, diff) * pow(scaling_coeff, i)
		
	power.set_value(total)
	print("Potentiel: " + str(total))
	
func add_to(p_el, i):
	elements.insert(i, p_el)
	emit_signal("incantation_has_changed")
	power_evaluation()
	
func append(p_el):
	elements.append(p_el)
	emit_signal("incantation_has_changed")
	power_evaluation()
	
func remove(i: int):
	elements.remove(i)
	index = index % len(elements)
	emit_signal("incantation_has_changed")
	power_evaluation()
	
func remove_by_element(p_el):
	var i = elements.find(p_el)
	remove(i)
	
func get_current_element() -> Array:
	return elements[index]
	
func reverse_gear(n = 1):
	index = max(0, index - n)
	
func next() -> bool:
	index = (index + 1) % len(elements)
	return index == 0
	
func get_index() -> int:
	return index
	
func get_len() -> int:
	return len(elements)
	
func get_pattern_element(i: int):
	return elements[i]

func get_list() -> Array:
	return elements.duplicate()
	
func get_power(bonus = 0.0, for_display_only = false) -> float:
	if for_display_only:
		return power.get_value()
	else:
		return power.apply(bonus)
	
func set_coeff(value: float):
	scaling_coeff = value
	
func set_index(i: int):
	index = i
	
func set_elements(L: Array):
	elements = L.duplicate()
	power_evaluation()
	if index < len(elements):
		index = 0
	emit_signal("incantation_has_changed")
