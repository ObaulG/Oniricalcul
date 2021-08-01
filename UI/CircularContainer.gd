tool
extends Control


var completance = 0.0 setget _private_set, _private_get
var angle = 0.0 setget _private_set, _private_get
var appear_at_once = false setget _private_set, _private_get


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
		
	#determining smallest child size in container
	var min_child_size = Vector2()
	for child in children:
		var size = _get_child_min_size(child)
		min_child_size.x = max(min_child_size.x, size.x)
		min_child_size.y = max(min_child_size.y, size.y)
	
	var radius = min(rect.size.x - min_child_size.x, rect.size.y - min_child_size.y) / 2
	
	var angle_required = 0
	var total_stretch_ratio = 0
	var angle_for_child = []
	for child in children:
		var angle = _get_max_angle_for_diagonal(_get_child_min_size(child).length(), radius)
		angle_required += angle
		angle_for_child.push_back(angle)
		total_stretch_ratio += _get_child_stretch_ratio(child)
	
	if total_stretch_ratio > 0: # Division by zero otherwise
		for i in range(children.size()): 
			var child = children[i]
			angle_for_child[i] += (2 * PI - angle_required) * _get_child_stretch_ratio(child) / total_stretch_ratio
	
	var angle_reached = _start_angle
	if !_start_empty:
		angle_reached -= angle_for_child[0] / 2
	
	var appear = _percent_visible
	if !_appear_at_once:
		appear *= children.size()
	
	for i in range(children.size()):
		var child = children[i]
		_put_child_at_angle(child, radius, origin, angle_reached, angle_for_child[i], clamp(appear, 0, 1))
		angle_reached += angle_for_child[i]
		if !_appear_at_once:
			appear -= 1
	pass
	
func get_completance():
	return completance

func set_completance(value: float):
	completance = clamp(value, 0.0, 1.0)
	_place()
	
func get_angle():
	return angle

func set_angle(value: float):
	angle = clamp(value, 0.0, 1.0)
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
		{type = TYPE_REAL, name = "angle", hint = PROPERTY_HINT_RANGE, hint_string = "-1080,1080,0.01"},
	]

func _set(property, value):
	if property == "completance": set_completance(value)
	elif property == "angle": set_angle(value)
	else:
		return false
	
	return true # When return false doesn't happen

func _get(property):
	if property == "completance": return completance
	elif property == "angle": return angle

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
