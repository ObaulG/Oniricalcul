class_name SoundPlay
extends Reference

const INT_PATTERN := "\\d+"

var sound_pos : int
var sound_id : int
	
func _init(_position: int, _tag_string: String) -> void:
	
	var _id_regex := RegEx.new()
	_id_regex.compile(INT_PATTERN)
	sound_id = int(_id_regex.search(_tag_string).get_string())
	sound_pos = int(clamp(_position - 1, 0, abs(_position)))
