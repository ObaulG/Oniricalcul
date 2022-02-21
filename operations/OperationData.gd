extends Object

class_name OperationData


var id: int
var name: Dictionary
var descr: Dictionary
var hardness_array: Array
var potential_array: Array
var answer_type: int
var icon: Texture

#init works from json dict
func _init(dict: Dictionary):
	id = dict["id"]
	name = {}
	descr = {}
	for lang in dict["str_data"].keys():
		name[lang] = dict["str_data"][lang]["name"]
		descr[lang] = dict["str_data"][lang]["descr"]
		
	#these values should be integers but they are stored as floats...
	hardness_array = Array(dict["hardness_list"])
	potential_array = Array(dict["potential_list"])
	answer_type = dict["answer_type"]
	
func get_hardness_array() -> Array:
	return hardness_array
	
func get_potential_array() -> Array:
	return potential_array
	
func get_answer_type() -> int:
	return answer_type
	
#dirty but it works
func get_potential(hardness: float) -> int:
	var index = hardness_array.find(hardness)
	return potential_array[index]
	
func get_name() -> String:
	return name[global.lang]

func get_icon() -> Texture:
	return icon
	
func set_icon(texture: Texture):
	icon = texture
	
func get_descr() -> String:
	return descr[global.lang]

func _to_string() -> String:
	return get_name() + str(get_potential_array())
