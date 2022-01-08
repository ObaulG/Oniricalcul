extends Control

signal nb_selected_operations_changed(n)

signal operation_confirmed_and_incantation_updated(index)

class_name Incantation_Operations

var grid
var nb_op
var size
var current
var list
var potential_label

var rollback_list
var operations_selectable: bool
var multiple_selection: bool

func _ready():
	grid = $MarginContainer/VBoxContainer/GridContainer
	potential_label = $MarginContainer/VBoxContainer/potential
	
	nb_op = Pattern.MAX_OP

	for i in range(nb_op):
		var operation = global.operation_display.instance()
		grid.add_child(operation)
		operation.connect("operation_confirmed", self, "on_operation_confirmed")
		operation.connect("operation_unselected", self, "on_operation_unselected")
		operation.connect("operation_selected", self, "on_operation_selected")
		operation.set_index(i)
	current = -1
	rollback_list = []
	operations_selectable = false
	multiple_selection = false
	
func update_operations(L: Array, dragable = false):
	list = L.duplicate()
	var n = len(L)
	var potential = 0
	
	for i in range(nb_op):
		if i < n:
			var type = L[i][0]
			var diff = L[i][1]
			potential += global.get_op_power(type, diff)
			var subtype: int
			if len(L[i]) == 3:
				subtype = L[i][2]
			else:
				subtype = -1
			get_operation_by_index(i).change_operation(type, diff, subtype)
		else:
			get_operation_by_index(i).clean()
	update_potential(potential)

func update_potential(p: int):
	potential_label.text = "Potential: " + str(p)
	
func set_operations_selectable(b = true, multiple = false):
	operations_selectable = b
	multiple_selection = multiple
	for op in grid.get_children():
		op.set_selectable(b)
		
func change_current_index(i: int):
	current = i
	if current >= 0:
		pass #Emphasis of current op

func remove_operation_by_index(i: int):
	get_operation_by_index(i).clean()
	
func assign_operation_to_index(pattern_el: Array, i: int):
	assert (i >= 0 and i < 8)
	get_operation_by_index(i).clean()
	get_operation_by_index(i).change_operation(pattern_el[0], pattern_el[1])
	
func get_operation_by_index(i: int):
	assert (i >= 0 and i < 8)
	return grid.get_child(i)
	
func get_current_selected_operations():
	var selected = []
	for op in grid.get_children():
		if op.is_selected():
			selected.append(op)
	return selected
	
func on_operation_selected(index: int):
	print("Le noeud Incantation a reçu la sélection de l'opération d'index " + str(index))
	emit_signal("nb_selected_operations_changed", len(get_current_selected_operations()))

func on_operation_unselected(i: int):
	print("Le noeud Incantation a reçu la désélection de l'opération d'index " + str(i))
	get_operation_by_index(i).set_selected(false)
	emit_signal("nb_selected_operations_changed", len(get_current_selected_operations()))
	
func on_operation_confirmed(index: int):
	print("Le noeud Incantation a reçu la confirmation de changement de l'opération d'index " + str(index))
	emit_signal("operation_confirmed_and_incantation_updated", index)


func _on_Incantation_Operations_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed :
			print("Incantation Clic " + str(event.position))

