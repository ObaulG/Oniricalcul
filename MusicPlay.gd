class_name MusicPlay
extends Reference


var music_name : String
var music_pos : int

const STRING_PARAM_PATTERN := "({m=[a-zA-Z0-9_]{2,}[}])"
func _init(_position: int, _tag_string: String) -> void:
	
	var _id_regex := RegEx.new()
	_id_regex.compile(STRING_PARAM_PATTERN)
	music_name = str(_id_regex.search(_tag_string).get_string())
	music_pos = int(clamp(_position - 1, 0, abs(_position)))
