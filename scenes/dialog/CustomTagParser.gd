# Thanks to:
# https://github.com/ericdsw/dialogue_system_test

class_name CustomTagParser
extends Node

enum EFFECTS{
	PAUSE,
	SOUND,
	VOLUME,
	PITCH,
	SPEED,
}
# Regular expression to find {p=%d} tags
const PAUSE_PATTERN := "({p=\\d([.]\\d+)?[}])"

const SOUND_PATTERN := "({s=\\d([.]\\d+)?[}])"
const VOLUME_PATTERN := "({v=\\d([.]\\d+)?[}])"
const PITCH_PATTERN := "({h=\\d([.]\\d+)?[}])"
const SPEED_PATTERN := "({c=\\d([.]\\d+)?[}])"
# Additional cleanup patterns
const FLOAT_PATTERN := "\\d+\\.\\d+"
const BBCODE_I_PATTERN := "\\[(?!\\/)(.*?)\\]"
const BBCODE_E_PATTERN := "\\[\\/(.*?)\\]"

# Not that we are defining here that all of our custom tags will be defined as {%s}, so
# we use this global pattern to match all of them.
const CUSTOM_TAG_PATTERN := "({(.*?)})"

# Lists of custom effects.
var _pauses := []
var _sounds := []
var _volumes := []
var _pitches := []
var _speeds := []

# Pause Regex
var _pause_regex := RegEx.new()
var _sound_regex := RegEx.new()
var _volume_regex := RegEx.new()
var _pitch_regex := RegEx.new()
var _speed_regex := RegEx.new()

# Auxiliary Regexes
var _float_regex := RegEx.new()
var _bbcode_i_regex := RegEx.new()
var _bbcode_e_regex := RegEx.new()
var _custom_tag_regex := RegEx.new()

signal pause_requested(duration)
signal sound_requested(id)
signal volume_change_requested(value)
signal pitch_change_requested(value)
signal speed_change_requested(value)
# ================================ Lifecycle ================================ #

func _ready() -> void:

	# Tags
	_pause_regex.compile(PAUSE_PATTERN)
	_sound_regex.compile(SOUND_PATTERN)
	_volume_regex.compile(VOLUME_PATTERN)
	_pitch_regex.compile(PITCH_PATTERN)
	_speed_regex.compile(SPEED_PATTERN)
	# Auxiliary
	_float_regex.compile(FLOAT_PATTERN)
	_bbcode_i_regex.compile(BBCODE_I_PATTERN)
	_bbcode_e_regex.compile(BBCODE_E_PATTERN)
	_custom_tag_regex.compile(CUSTOM_TAG_PATTERN)

# ================================= Public ================================== #

# Will attempt to extract all tags that follow the {p=%d} pattern, and will return a
# version of the provided string without them. This basically resets the _pauses array
# and performs the first call to _extract_next_pause
func extract_pauses_from_string(source_string: String) -> String:
	_pauses = []
	_find_pauses(source_string)
	return _extract_tags(source_string)

func extract_tags_from_string(source_string: String) -> String:
	_pauses = []
	_sounds = []
	_volumes = []
	_pitches = []
	_speeds = []
	_find_tags(source_string)
	return _extract_tags(source_string)
	
# Checks if a pause must be executed for the current offset
func check_at_position(pos: int) -> void:
	
	for _pause in _pauses:
		if _pause.pause_pos == pos:
			print("Signal de pause prêt à l'envoi")
			emit_signal("pause_requested", _pause.duration)
			
	for _sound in _sounds:
		if _sound.sound_pos == pos:
			emit_signal("sound_requested", _sound.sound_id)
			
	for _volume in _volumes:
		if _volume.volume_pos == pos:
			emit_signal("volume_change_requested", _volume.value)
			
	for _pitch in _pitches:
		if _pitch.pitch_pos == pos:
			emit_signal("pitch_change_requested", _pitch.value)
			
	for _speed in _speeds:
		if _speed.speed_pos == pos:
			print("Signal chgt vitesse prêt à l'envoi")
			emit_signal("speed_change_requested", _speed.value)
	
# ================================ Private ================================== #

# Detects all pauses currently present on the string, and registers them to the _pauses array
func _find_pauses(from_string: String) -> void:

	var _found_pauses := _pause_regex.search_all(from_string)

	for _pause_regex_result in _found_pauses:
		var _tag_string := _pause_regex_result.get_string() as String
		var _tag_position := _adjust_position(
			_pause_regex_result.get_start(),
			from_string
		)
		var _pause = Pause.new(_tag_position, _tag_string)
		_pauses.append(_pause)

func _find_tags(from_string: String) -> void:

	var _found_pauses := _pause_regex.search_all(from_string)
	var _found_sounds := _sound_regex.search_all(from_string)
	var _found_volumes := _volume_regex.search_all(from_string)
	var _found_pitches := _pitch_regex.search_all(from_string)
	var _found_speeds := _speed_regex.search_all(from_string)
	
	for _pause_regex_result in _found_pauses:
		
		var _tag_string := _pause_regex_result.get_string() as String

		var _tag_position := _adjust_position(
			_pause_regex_result.get_start(),
			from_string
		)
		var _pause = Pause.new(_tag_position, _tag_string)
		_pauses.append(_pause)
	
	
	for _sound_regex_result in _found_sounds:
		var _tag_string := _sound_regex_result.get_string() as String

		var _tag_position := _adjust_position(
			_sound_regex_result.get_start(),
			from_string
		)
		var _sound = SoundPlay.new(_tag_position, _tag_string)
		_sounds.append(_sound)
	
	for _volume_regex_result in _found_volumes:
		var _tag_string := _volume_regex_result.get_string() as String
		
		var _tag_position := _adjust_position(
			_volume_regex_result.get_start(),
			from_string
		)
		var _volume = VolumeChange.new(_tag_position, _tag_string)
		_volumes.append(_volume)
	
	for _pitch_regex_result in _found_pitches:
		var _tag_string := _pitch_regex_result.get_string() as String
		
		var _tag_position := _adjust_position(
			_pitch_regex_result.get_start(),
			from_string
		)
		var _pitch = Pitch.new(_tag_position, _tag_string)
		_pitches.append(_pitch)
	
	for _speed_regex_result in _found_speeds:
		var _tag_string := _speed_regex_result.get_string() as String

		var _tag_position := _adjust_position(
			_speed_regex_result.get_start(),
			from_string
		)
		var _speed = SpeedChange.new(_tag_position, _tag_string)
		_speeds.append(_speed)
		
		
# Adjusts the provided position based on the bbcodes and custom tags that are found to the left 
# of the provided string.
func _adjust_position(pos: int, source_string: String) -> int:
	
	# Previous tags
	var _new_pos := pos
	var _left_of_pos := source_string.left(pos)

	var _all_prev_tags := _custom_tag_regex.search_all(_left_of_pos)
	for _tag_result in _all_prev_tags:
		_new_pos -= _tag_result.get_string().length()
	
	var _all_prev_start_bbcodes := _bbcode_i_regex.search_all(_left_of_pos)
	for _tag_result in _all_prev_start_bbcodes:
		_new_pos -= _tag_result.get_string().length()

	var _all_prev_end_bbcodes := _bbcode_e_regex.search_all(_left_of_pos)
	for _tag_result in _all_prev_end_bbcodes:
		_new_pos -= _tag_result.get_string().length()

	return _new_pos

# Removes all custom tags from the string
func _extract_tags(from_string: String) -> String:
	return _custom_tag_regex.sub(from_string, "", true)

