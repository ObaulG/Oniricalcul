class_name Pitch
extends Reference

const FLOAT_PATTERN := "\\d+\\.\\d+"

var pitch_pos : int
var value : float
	
func _init(_position: int, _tag_string: String) -> void:
	
	var _pitch_regex := RegEx.new()
	_pitch_regex.compile(FLOAT_PATTERN)
	
	value = int(_pitch_regex.search(_tag_string).get_string())
	pitch_pos = int(clamp(_position - 1, 0, abs(_position)))

