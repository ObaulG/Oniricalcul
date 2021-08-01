extends Container

class_name BonusMenu

enum STATE {IDLE, REPLACING_OP, SWAPPING, SELECTING}
signal player_ask_to_buy_operation(shop_index)
signal player_ask_to_buy_bonus(shop_index)
signal player_ask_to_buy_stat(shop_index)
signal player_wants_to_erase_operation()
signal player_wants_to_swap_operations()
signal on_pop_up_ok_press()
signal on_pop_up_cancel()

var operations_node
var bonus_list_node
var incantation
var points_label
var new_operations_grid
var timedisplay
var erase_price
var swap_price

var state
var selected_op_index: int
var confirm_pop_up_incantation
var operation_dragged
var pop_up_ok_button
var pop_up_cancel_button
var swap_button
var erase_button
var cancel_button


func _ready():
	operations_node = $MarginContainer/vbox/bonus_zone/new_operations/Incantation_Operations
	bonus_list_node = $MarginContainer/vbox/bonus_zone/vbox_items/list
	incantation = $MarginContainer/vbox/bonus_zone/new_operations/Incantation_Operations
	points_label = $MarginContainer/vbox/HBoxContainer/points
	new_operations_grid = $MarginContainer/vbox/bonus_zone/new_operations/new_operations
	confirm_pop_up_incantation = $ConfirmationDialog
	timedisplay = $MarginContainer/vbox/HBoxContainer/TimeDisplay
	swap_button = $MarginContainer/vbox/bonus_zone/new_operations/swap_button
	erase_button = $MarginContainer/vbox/bonus_zone/new_operations/erase_button
	cancel_button = $MarginContainer/vbox/bonus_zone/new_operations/cancel_button
	pop_up_ok_button = confirm_pop_up_incantation.get_ok()
	pop_up_cancel_button = confirm_pop_up_incantation.get_cancel()
	connect("on_pop_up_ok_press", self, "on_pop_up_ok_press")
	connect("on_pop_up_cancel", self, "on_pop_up_cancel")
	selected_op_index = -1
	
func change_state(state):
	set_state(state)
	match state:
		STATE.IDLE:
			swap_button.disabled = false
			erase_button.disabled = false
			cancel_button.disabled = true
			set_shop_operations_buyable(true)
			make_op_selectionnable(false, false)
		STATE.REPLACING_OP:
			swap_button.disabled = true
			erase_button.disabled = true
			cancel_button.disabled = false
			make_op_selectionnable(true, false)
		STATE.SWAPPING:
			swap_button.disabled = true
			erase_button.disabled = true
			cancel_button.disabled = false
			make_op_selectionnable(true, true)
		STATE.SELECTING:
			swap_button.disabled = true
			erase_button.disabled = true
			cancel_button.disabled = false
			make_op_selectionnable(true, true)
			
func set_pattern(list: Array):
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
		
	for op in list_enemy:
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
		new_op.set_price(10 + 2*pow(diff,2))
		new_op.set_display_type(Operation_Display.DISPLAY_TYPE.BUYING)
		new_op.connect("wants_to_buy_op", self, "on_trying_to_buy_op")
		
func set_display_potential(value: int):
	incantation.update_potential(value)
	
func set_time(value):
	timedisplay.update_time(value)
	
func set_bonus(list: Array):
	pass
	
func set_new_stats(list: Array):
	pass

func make_op_selectionnable(b = true, multi = false):
	incantation.set_operations_selectable(b, multi)
	
func select_operation(n = 1):
	selected_op_index = -1
	set_shop_operations_buyable(false)
	change_state(STATE.SWAPPING)
	print("Sélectionnez une opération")
	# user selects the operation to change
	selected_op_index = yield(incantation, "operation_selected")
	change_state(STATE.IDLE)
	return selected_op_index
	
func select_operations_to_swap():
	change_state(STATE.SWAPPING)
	var index1: int
	var index2: int
	
	print("Sélectionnez op1")
	
func pop_up_result(ok_pressed: bool):
	if ok_pressed:
		return selected_op_index
	else:
		return -1

func on_trying_to_buy_op(op):
	emit_signal("player_ask_to_buy_operation", op)


func _on_operation_confirmed(index):
	return index


func _on_pop_up_ok_press():
	pop_up_result(true)


func _on_pop_up_cancel():
	pop_up_result(false)


func set_shop_operations_buyable(b = true):
	for op in new_operations_grid.get_children():
		if op is Operation_Display:
			if op.display_type != Operation_Display.DISPLAY_TYPE.BOUGHT:
				if b:
					op.set_display_type(Operation_Display.DISPLAY_TYPE.BUYING)
				else:
					op.set_display_type(Operation_Display.DISPLAY_TYPE.BASIC)
					
func _on_swap_button_down():
	emit_signal("player_wants_to_swap_operations")

func _on_cancel_button_down():
	set_shop_operations_buyable(true)
	change_state(STATE.IDLE)

func _on_domain_p1_new_money_value(money):
	print("Nouvelle valeur de monnaie recue")
	points_label.text = "Argent: " + str(money)


func _on_erase_button_down():
	emit_signal("player_wants_to_erase_operation")
