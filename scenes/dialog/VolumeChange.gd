class_name VolumeChange
extends Reference

const FLOAT_PATTERN := "\\d+\\.\\d+"

var volume_pos : int
var value : float
	
func _init(_position: int, _tag_string: String) -> void:
	
	var _volume_regex := RegEx.new()
	_volume_regex.compile(FLOAT_PATTERN)
	
	value = int(_volume_regex.search(_tag_string).get_string())
	volume_pos = int(clamp(_position - 1, 0, abs(_position)))
