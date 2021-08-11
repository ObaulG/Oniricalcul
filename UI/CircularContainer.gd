# Inspired by Kobuge Games CircularConttainer.
tool
extends Container

const BASE_DIMENSIONS = Vector2(300,300)

var completance = 0.0 setget _private_set, _private_get
var base_angle = 0.0 setget _private_set, _private_get
var appear_at_once = false setget _private_set, _private_get
var _custom_animator_func = null setget _private_set, _private_get

## Cached variables ##

#min size of rect.
var _cached_min_size_key = "" setget _private_set, _private_get
var _cached_min_size = null setget _private_set, _private_get
var _cached_min_size_dirty = false setget _private_set, _private_get


# Called when the node enters the scene tree for the first time.
func _ready():
	# rearrange children if one is added or retired
	connect("sort_children", self, "_place")
	_place()

func _place():
	var rect = get_rect()
	var origin = rect.size / 2
	
	var children = _get_filtered_children()
	
	#stops if there is no object to display
	if children.size() == 0:
		return
		
	#determining biggest child size in container
	var min_child_size = Vector2()
	for child in children:
		var size = child.get_combined_minimum_size()
		min_child_size.x = max(min_child_size.x, size.x)
		min_child_size.y = max(min_child_size.y, size.y)
	
	var radius = min(rect.size.x - min_child_size.x, rect.size.y - min_child_size.y) / 2
	
	var angle = base_angle
	var n = len(children)
	var final_positions = []
	for child in children:
		if child is Control:
			var final_pos = origin + Vector2(0, -radius).rotated(deg2rad(angle))
			angle += 360/n
			child.set_position(final_pos)
			
func get_completance():
	return completance

func set_completance(value: float):
	completance = clamp(value, 0.0, 1.0)
	_place()
	
func get_base_angle():
	return base_angle

func set_base_angle(value: float):
	base_angle = clamp(value, -1080, 1080)
	_place()
	
func is_appear_all_at_once() -> bool:
	return appear_at_once

func set_appear_all_at_once(value: bool):
	appear_at_once = value
	_place()
	
func _get_property_list():
	return [
		{usage = PROPERTY_USAGE_CATEGORY, type = TYPE_NIL, name = "CircularContainer"},
		{type = TYPE_REAL, name = "completance",hint = PROPERTY_HINT_RANGE, hint_string = "0,1,0.01"},
		{type = TYPE_REAL, name = "base_angle", hint = PROPERTY_HINT_RANGE, hint_string = "-1080,1080,0.01"},
	]

func _set(property, value):
	if property == "completance": set_completance(value)
	elif property == "base_angle": set_base_angle(value)
	else:
		return false
	
	return true # When return false doesn't happen

func _get(property):
	if property == "completance": return completance
	elif property == "base_angle": return base_angle

func _private_set(value = null):
	print("Invalid access to private variable!")
	return value

func _private_get(value = null):
	print("Invalid access to private variable!")
	return value
	
	
func _get_filtered_children():
	var children = get_children()
	var i = children.size()
	while i > 0:
		i -= 1
		var keep = false
		if children[i] is Control:
			keep = true
		if children[i] is CanvasItem and children[i].visible==false:
			keep = false
		
		if !keep:
			children.remove(i)
	return children


func set_custom_animator(object, method): # Params of animator function : node (Control or Node2D), center_pos, target_pos, time (0..1)
	_custom_animator_func = funcref(object, method)
