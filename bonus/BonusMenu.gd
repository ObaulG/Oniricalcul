extends Control

class_name BonusMenuBis

enum BONUS_ACTION{
	BUY_OPERATION = 1,
	BUY_BONUS,
	BUY_STATS,
	ERASE_OPERATION,
	SWAP_OPERATIONS
}
enum STATE {IDLE, REPLACING_OP, SWAPPING, SELECTING}

signal player_asks_for_action(gid, action_type, element)
signal operations_selection_done(L)
signal on_pop_up_ok_press()
signal on_pop_up_cancel()

var game_id

var operations_node
var bonus_list_node
var incantation
var points_label
var new_operations_grid
var timedisplay
var erase_price
var swap_price

var state
var nb_selection_needed: int
var confirm_pop_up_incantation
var operation_dragged
var pop_up_ok_button
var pop_up_cancel_button
var swap_button
var erase_button
var cancel_button

var timer
onready var state_label = $state_label

func _ready():
	operations_node = $MarginContainer/vbox/bonus_zone/new_operations/Incantation_Operations
	bonus_list_node = $MarginContainer/vbox/bonus_zone/vbox_items/list
	incantation = $MarginContainer/vbox/bonus_zone/new_operations/Incantation_Operations
	points_label = $MarginContainer/vbox/CenterContainer2/HBoxContainer/points
	new_operations_grid = $MarginContainer/vbox/bonus_zone/new_operations/new_operations
	confirm_pop_up_incantation = $ConfirmationDialog
	timer = $Timer
	timedisplay = $MarginContainer/vbox/CenterContainer/timer_display
	swap_button = $MarginContainer/vbox/bonus_zone/new_operations/swap_button
	erase_button = $MarginContainer/vbox/bonus_zone/new_operations/erase_button
	cancel_button = $MarginContainer/vbox/bonus_zone/new_operations/cancel_button
	pop_up_ok_button = confirm_pop_up_incantation.get_ok()
	pop_up_cancel_button = confirm_pop_up_incantation.get_cancel()
	connect("on_pop_up_ok_press", self, "on_pop_up_ok_press")
	connect("on_pop_up_cancel", self, "on_pop_up_cancel")
	change_state(STATE.IDLE)
	
	game_id = get_parent().game_id

func _process(_delta):
	pass
		
func change_state(state):
	set_state(state)
	match state:
		STATE.IDLE:
			state_label.text = "Normal"
			nb_selection_needed = 0
			swap_button.disabled = false
			erase_button.disabled = false
			cancel_button.disabled = true
			set_shop_operations_buyable(true)
			make_op_selectionnable(false, false)
		STATE.REPLACING_OP:
			state_label.text = "Remplacement"
			nb_selection_needed = 1
			swap_button.disabled = true
			erase_button.disabled = true
			cancel_button.disabled = false
			make_op_selectionnable(true, false)
		STATE.SWAPPING:
			state_label.text = "Echange"
			nb_selection_needed = 2
			swap_button.disabled = true
			erase_button.disabled = true
			cancel_button.disabled = false
			make_op_selectionnable(true, true)
		STATE.SELECTING:
			state_label.text = "Sélection"
			nb_selection_needed = 1
			swap_button.disabled = true
			erase_button.disabled = true
			cancel_button.disabled = false
			make_op_selectionnable(true, true)
			
func end_selection():
	change_state(STATE.IDLE)
	nb_selection_needed = 0

func get_selected_operations():
	return incantation.get_current_selected_operations()
	
func set_pattern(list: Array):
	print("UI Incantation display")
	incantation.update_operations(list)
	
func set_state(state):
	self.state = state
	
func set_erase_price(value):
	erase_price = value
	erase_button.text = "Effacer (" + str(erase_price) + "points)"
	
func set_swap_price(value):
	swap_price = value
	swap_button.text = "Echanger (" + str(swap_price) + "points)"
	
func set_new_operations(list_player: Array, list_enemy: Array):
	for child in new_operations_grid.get_children():
		new_operations_grid.remove_child(child)
		child.queue_free()
		
	var i = 0
	for op in list_player:
		var type = op[0]
		var diff = op[1]
		var subtype
		if len(op) == 3:
			subtype = op[2]
		else:
			subtype = -1
		var new_op = global.operation_display.instance()
		new_operations_grid.add_child(new_op)
		new_op.change_operation(type, diff, subtype)
		new_op.set_display_type(Operation_Display.DISPLAY_TYPE.BUYING)
		new_op.set_price(5 + 2*pow(diff,2))
		new_op.connect("wants_to_buy_op", self, "on_trying_to_buy_op")
		new_op.set_name("myop"+str(i))
		i+=1
	i = 0
	for op in list_enemy:
		var type = op[0]
		var diff = op[1]

		var new_op = global.operation_display.instance()
		new_operations_grid.add_child(new_op)
		new_op.change_operation(type, diff)
		new_op.set_price(10 + 2*pow(diff,2))
		new_op.set_display_type(Operation_Display.DISPLAY_TYPE.BUYING)
		new_op.connect("wants_to_buy_op", self, "on_trying_to_buy_op")
		new_op.set_name("enemyop"+str(i))
		i+=1
		
func get_erase_price():
	return erase_price
	
func get_swap_price():
	return swap_price
	
func get_new_operations():
	var list_of_new_op = []
	for child in new_operations_grid.get_children():
		list_of_new_op.append(child)
	return list_of_new_op
	
func get_buyable_new_operations():
	var list_of_new_op = []
	for child in new_operations_grid.get_children():
		if child.is_buyable():
			list_of_new_op.append(child)
	return list_of_new_op
	
func get_shop_element_by_name(s: String):
	#for the moment, only operations are buyable
	var node = new_operations_grid.get_node(s)
	return node

func set_display_potential(value: int):
	incantation.update_potential(value)
	
func set_time(value):
	timedisplay.set_new_value(value)
	
func set_bonus(list: Array):
	pass
	
func set_money_value(n):
	points_label.text = "Argent : " + str(n)
	
func set_new_stats(list: Array):
	pass

func make_op_selectionnable(b = true, multi = false):
	incantation.set_operations_selectable(b, multi)

func on_trying_to_buy_op(op):
	print("You try to buy " + str(op))
	print("Game id: " + str(game_id))
	emit_signal("player_asks_for_action", game_id, BONUS_ACTION.BUY_OPERATION, op)


func _on_operation_confirmed(index):
	return index

func set_shop_operations_buyable(b = true):
	for op in new_operations_grid.get_children():
		if op is Operation_Display:
			if op.display_type != Operation_Display.DISPLAY_TYPE.BOUGHT:
				if b:
					op.set_display_type(Operation_Display.DISPLAY_TYPE.BUYING)
				else:
					op.set_display_type(Operation_Display.DISPLAY_TYPE.BASIC)
					
func _on_swap_button_down():
	emit_signal("player_asks_for_action", game_id, BONUS_ACTION.SWAP_OPERATIONS, -1)

func _on_cancel_button_down():
	set_shop_operations_buyable(true)
	change_state(STATE.IDLE)

func _on_erase_button_down():
	emit_signal("player_asks_for_action", game_id, BONUS_ACTION.ERASE_OPERATION, null)

#if we have the correct number of operations selected
#for the current state then we call the function needed
func _on_Incantation_Operations_nb_selected_operations_changed(n):
	print("operations selected: " + str(n))
	match state:
		STATE.IDLE:
			pass
		STATE.REPLACING_OP:
			pass
		STATE.SWAPPING:
			pass
		STATE.SELECTING:
			pass

	if n == nb_selection_needed:
		emit_signal("operations_selection_done", get_selected_operations(), state)
		end_selection()
		
func _on_spellbook_incantation_has_changed(L: Array):
	set_pattern(L)
	
func _on_spellbook_money_value_has_changed(gid, n):
	if gid == game_id:
		points_label.text = "Argent : " + str(n)
