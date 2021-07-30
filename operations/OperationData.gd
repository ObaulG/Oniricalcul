extends Object

class_name OperationData


var id: int
var name: Dictionary
var descr: Dictionary
var hardness_array: PoolIntArray
var potential_array: PoolIntArray

var icon: Texture

#init works from json dict
func _init(dict: Dictionary):
	id = dict["id"]
	name = {}
	descr = {}
	for lang in dict["str_data"].keys():
		name[lang] = dict["str_data"][lang]["name"]
		descr[lang] = dict["str_data"][lang]["descr"]
	hardness_array = dict["hardness_list"]
	potential_array = dict["potential_list"]

func get_hardness_array() -> PoolIntArray:
	return hardness_array
	
func get_potential_array() -> PoolIntArray:
	return potential_array
	
func get_potential(hardness: int) -> int:
	return potential_array[hardness]
	
func get_name() -> String:
	return name[global.lang]

func get_icon() -> Texture:
	return icon
	
func set_icon(texture: Texture):
	icon = texture
	
func get_descr() -> String:
	return descr[global.lang]
