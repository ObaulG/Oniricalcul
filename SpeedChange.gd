class_name SpeedChange
extends Reference

const FLOAT_PATTERN := "\\d+\\.\\d+"

var speed_pos : int
var value : float
	
func _init(_position: int, _tag_string: String) -> void:
	
	var _speed_regex := RegEx.new()
	_speed_regex.compile(FLOAT_PATTERN)
	
	value = int(_speed_regex.search(_tag_string).get_string())
	speed_pos = int(clamp(_position - 1, 0, abs(_position)))
