class_name AnimationPlay
extends Reference


var animation_name : String
var animation_target : String
var animation_pos : int

const STRING_PARAM_PATTERN := "({m=[a-zA-Z0-9_]{2,}[}])"

func _init(_position: int, _tag_string: String) -> void:
	
	var _id_regex := RegEx.new()
	_id_regex.compile(STRING_PARAM_PATTERN)
	var regex_result = _id_regex.search_all(_tag_string)
	animation_name = str(regex_result[0].get_string())
	animation_target = str(regex_result[1].get_string(1))
	animation_pos = int(clamp(_position - 1, 0, abs(_position)))

