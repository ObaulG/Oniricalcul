extends Control

signal operation_selected(index)
signal operation_confirmed_and_incantation_updated(index)

class_name Incantation

enum DISPLAY_TYPE{FULL, SHORT}
var display_type

var nb_op
var current_nb_op
var size

# List of Operation_Display nodes
var operations_list: Array

var rollback_list
var operations_selectable: bool
var multiple_selection: bool

func _ready():
	display_type = DISPLAY_TYPE.FULL
	current_nb_op = 3
	nb_op = Pattern.MAX_OP
	operations_list = [
		$operation,
		$operation2,
		$operation3,
		$operation4,
		$operation5,
		$operation6,
		$operation7,
		$operation8,
	]
	var i = 0
	for op_node in operations_list:

		op_node.connect("operation_confirmed", self, "on_operation_confirmed")
		op_node.connect("operation_unselected", self, "on_operation_unselected")
		op_node.connect("operation_selected", self, "on_operation_selected")
		op_node.set_index(i)
		op_node.clean()
		i+=1
	rollback_list = []
	operations_selectable = false
	multiple_selection = false
	

func update_operations(L: Array, dragable = false):

	var n = len(L)
	var potential = 0
	
	for i in range(nb_op):
		var op = get_operation_by_index(i)
		
		if i < n:
			var type = L[i][0]
			var diff = L[i][1]
			potential += global.get_op_power(type, diff)
			var subtype: int
			if len(L[i]) == 3:
				subtype = L[i][2]
			else:
				subtype = -1
			op.change_operation(type, diff, subtype)
		else:
			op.clean()
	current_nb_op = n
	update_potential(potential)

func update_nb_operations_in_incantation():
	var n = 0
	var end = false
	while n < 8 and not end:
		var op = operations_list[n].get_pattern_element()
		end = op[0] == -1
		if not end:
			n += 1
	current_nb_op = n
	
func get_operation_pattern() -> Array:
	var pattern = []
	for i in range(current_nb_op):
		var op = operations_list[i]
		pattern.append(op.get_pattern_element())
	return pattern

func update_potential(p: int):
	#potential_label.text = str(p)
	pass
	
func set_operations_selectable(b = true, multiple = false):
	operations_selectable = b
	multiple_selection = multiple
	for op in operations_list:
		op.set_selectable(b)
		
func get_operation_by_index(index: int):
	return operations_list[index]
	
func get_current_selected_operations(L: Array):
	var selected = []
	for i in range(len(operations_list)):
		if get_operation_by_index(i).is_selected():
			selected.append(i)
	return selected
	
func get_list():
	
	return operations_list
	
func on_operation_selected(index: int):
	emit_signal("operation_selected", index)
	if !multiple_selection:
		for i in range(len(operations_list)):
			var op = get_operation_by_index(i)
			if i == index:
				op.set_selected(true)
				print(i)
			else:
				op.set_selected(false)
	
func on_operation_unselected(index: int):
	get_operation_by_index(index).set_selected(false)
	emit_signal("operation_unselected", index)

func remove_operation_by_index(index: int):
	assert (index >= 0 and index < 8)
	get_operation_by_index(index).clean()
	
func assign_operation_to_index(pattern_el: Array, index: int):
	assert (index >= 0 and index < 8)
	get_operation_by_index(index).clean()
	get_operation_by_index(index).change_operation(pattern_el[0], pattern_el[1])
	
func on_operation_confirmed(index: int):
	emit_signal("operation_confirmed_and_incantation_updated", index)

func set_display_type(type):
	display_type = type
	match display_type:
		DISPLAY_TYPE.FULL:
			pass
		DISPLAY_TYPE.SHORT:
			pass

func _on_Incantation_Operations_gui_input(event):
	pass
#	if event is InputEventMouseButton:
#		if event.button_index == BUTTON_LEFT and event.pressed :
#			print("Incantation Clic " + str(event.position))

func _on_Spellbook_incantation_has_changed(L: Array):
	update_operations(L)
