extends Control

signal wants_to_buy_op(operation)
signal operation_selected(index)
signal operation_unselected(index)
signal operation_confirmed(index)

class_name Operation_Display

enum DISPLAY_TYPE {BASIC, BUYING, BOUGHT}
const VOID_COLOR: Color = Color("#555555")
const BACKGROUND_COLOR_DIFF: Dictionary = {
	1: Color("#A9D5D9"),
	2: Color("#62DC84"),
	3: Color("#1A7BE9"),
	4: Color("#F5F840"),
	5: Color("#CE11F8"),
}

var bg: ColorRect
var diff_label: Label
var sprite_node: Sprite
var price_label: Label
var buying_button: Button

var type: int
var subtype: int
var diff: int
var display_type: int
var index_in_incantation: int
var selectable: bool
var selected: bool
var clickzone
var clickrect
var selected_node
var dragable: bool

var price: int

func _ready():
	bg = $bg
	sprite_node = $MarginContainer/VBoxContainer/CenterContainer/sprite
	diff_label = $MarginContainer/VBoxContainer/diff
	price_label = $MarginContainer/VBoxContainer/price
	buying_button = $MarginContainer/VBoxContainer/Button
	clickzone = $Area2D
	clickrect = $Area2D/click_zone
	
	var atlas = AtlasTexture.new()
	atlas.set_atlas(global.sprite_sheet_operations)
	atlas.set_region(Rect2(256, 0, 64, 64))
	
	sprite_node.set_region(true)
	sprite_node.texture = atlas
	
	bg.color = VOID_COLOR
	
	set_display_type(DISPLAY_TYPE.BASIC)
	price = -1
	selectable = false
	selected = false
	dragable = true
	clean()
	
func _on_Window_gui_input(_event):
	pass
	
func change_operation(t: int, d: int, st = -1):
	#A modifier en fonction de la rareté.
	bg.color = BACKGROUND_COLOR_DIFF[d]
	type = t
	diff = d
	subtype = st
	diff_label.text = str(diff)
	
	var index = 0
	match type:
		1:
			index = 0
		2:
			index = 3
		3:
			index = 2
		4:
			index = 1
		_:
			index = 4
	sprite_node.texture.set_region(Rect2(index*64, 0, 64, 64))
	if t != -1:
		visible = true

func set_display_type(type: int):
	display_type = type
	if type == DISPLAY_TYPE.BASIC:
		buying_button.visible = false
		price_label.visible = false
	elif type == DISPLAY_TYPE.BUYING:
		buying_button.visible = true
		price_label.visible = true
	elif type == DISPLAY_TYPE.BOUGHT:
		# price = -1
		buying_button.visible = false
		price_label.visible = false
	else:
		pass

func set_price(value: int):
	price = value
	price_label.text = str(price) + " points"

func set_index(i: int):
	index_in_incantation = i

func clean():
	bg.color = VOID_COLOR
	sprite_node.texture.set_region(Rect2(4*64, 0, 64, 64))
	type = -1
	diff = -1
	subtype = -1
	diff_label.text = ""
	visible = false
	
func get_type():
	return type

func get_subtype():
	return subtype

func get_diff():
	return diff

func get_pattern_element() -> Array:
	return [type, diff]

func get_price() -> int:
	return price

func is_selected():
	return selected

func set_selectable(b: bool):
	if type != -1:
		selectable = b
		clickrect.set_disabled(!b)
		if !b:
			set_selected(false)

func set_selected(b: bool):
	if type != -1:
		selected = b
		$selected.visible = b

func _on_operation_focus_entered():
	pass # Replace with function body.

func _on_operation_focus_exited():
	pass # Replace with function body.

func _on_Button_pressed():
	emit_signal("wants_to_buy_op", self)

func _on_Area2D_input_event(viewport, event, shape_idx):
	print("CLIC")
	if event is InputEventMouseButton:
		if selectable and event.pressed and event.button_index == BUTTON_LEFT:
			if !selected:
				$selected.visible = true
				emit_signal("operation_selected", index_in_incantation)
			else:
				$selected.visible = false
				emit_signal("operation_unselected", index_in_incantation)


func _on_Area2D_mouse_entered():
	print("AAAA")


func _on_operation_gui_input(event):
	if event is InputEventMouseButton:
		if selectable and event.pressed and event.button_index == BUTTON_LEFT:
			if !selected:
				$selected.visible = true
				emit_signal("operation_selected", index_in_incantation)
			else:
				$selected.visible = false
				emit_signal("operation_unselected", index_in_incantation)
