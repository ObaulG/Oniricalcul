extends Control

signal nb_selected_operations_changed(n)

signal operation_confirmed_and_incantation_updated(index)

class_name Incantation_Operations

var grid
var nb_op
var size
var operations_list
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
	#Modifier la taille de l'objet en f. du nb d'op? à voir..
	operations_list = []
	for i in range(nb_op):
		var operation = global.operation_display.instance()
		grid.add_child(operation)
		operations_list.append(operation)
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
			operations_list[i].change_operation(type, diff, subtype)
		else:
			operations_list[i].clean()
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

func get_current_selected_operations():
	var selected = []
	for i in range(len(operations_list)):
		if operations_list[i].is_selected():
			selected.append(i)
	return selected
	
func on_operation_selected(index: int):
	print("Le noeud Incantation a reçu la sélection de l'opération d'index " + str(index))
	emit_signal("nb_selected_operations_changed", len(get_current_selected_operations()))
	if !multiple_selection:
		for i in range(len(operations_list)):
			if i == index:
				operations_list[index].set_selected(true)
				print(i)
			else:
				operations_list[index].set_selected(false)
	
func on_operation_unselected(index: int):
	print("Le noeud Incantation a reçu la désélection de l'opération d'index " + str(index))
	operations_list[index].set_selected(false)
	emit_signal("nb_selected_operations_changed", len(get_current_selected_operations()))

func remove_operation_by_index(index: int):
	assert (index >= 0 and index < 8)
	operations_list[index].clean()
	
func assign_operation_to_index(pattern_el: Array, index: int):
	assert (index >= 0 and index < 8)
	operations_list[index].clean()
	operations_list[index].change_operation(pattern_el[0], pattern_el[1])
	
func on_operation_confirmed(index: int):
	print("Le noeud Incantation a reçu la confirmation de changement de l'opération d'index " + str(index))
	emit_signal("operation_confirmed_and_incantation_updated", index)


func _on_Incantation_Operations_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed :
			print("Incantation Clic " + str(event.position))

