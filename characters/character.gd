extends Object

class_name Character

var id: int
var name: String
var descr: Dictionary
var game_info: String
var estimated_diff: int
var malus_level: int
var base_pattern: Array
var operation_preference: Dictionary
var difficulty_preference: Dictionary
var base_hp: int
var threat_type: int
var icon_texture: Texture

func _init(char_dico: Dictionary):
	self.id = char_dico["id"]
	self.name = char_dico["name"]
	self.descr = char_dico["descr"]
	self.game_info = char_dico["info"]
	self.estimated_diff = char_dico["difficulty"]
	self.malus_level = char_dico["malus_level"]
	self.base_pattern = char_dico["base_pattern"]
	self.operation_preference = char_dico["operations_preference"]
	self.difficulty_preference = char_dico["difficulty_preference"]
	self.base_hp = char_dico["hp"]
	self.threat_type = char_dico["threat_type"]
	
	var string_id = str(id)
	if len(string_id) < 2:
		string_id = "0" + string_id
	icon_texture = load("res://characters/"+string_id+"/icon.png")

func get_id():
	return id
	
func get_name():
	return name

func get_descr():
	return descr[global.lang]
	
func get_info():
	return game_info
	
func get_estimated_diff():
	return estimated_diff
	
func get_malus_level():
	return malus_level
	
func get_base_pattern():
	return base_pattern
	
func get_operation_preference():
	return operation_preference

func get_difficulty_preference():
	return difficulty_preference
	
func get_base_hp():
	return base_hp

func get_threat_type():
	return threat_type
	
func get_icon_texture():
	return icon_texture

func get_resized_icon_texture(_w, _h):
	pass
