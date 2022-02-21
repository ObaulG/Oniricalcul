extends Control

enum SELECTED {NUMERATOR, DENOMINATOR}

class_name FractionAnswer

var current_selected
var num_str: String
var den_str: String

onready var frac: FractionDisplay = $FractionDisplay
onready var arrow: TextureRect = $arrow

func _ready():
	current_selected = SELECTED.NUMERATOR
	frac.update_numerator(0)
	frac.update_denominator(0) #hehe
	num_str = ""
	den_str = ""
	
func change_selection(select):
	current_selected == select
	
func update_display():
	if current_selected == SELECTED.NUMERATOR:
		frac.update_numerator(int(num_str))
	else:
		frac.update_denominator(int(den_str))
	
func next_selection():
	if current_selected == SELECTED.NUMERATOR:
		change_selection(SELECTED.DENOMINATOR)
	else:
		change_selection(SELECTED.NUMERATOR)
		
func write_digit(d):
	if current_selected == SELECTED.NUMERATOR:
		num_str += str(d)
	else:
		den_str += str(d)
	update_display()
	
func delete_digit():
	if current_selected == SELECTED.NUMERATOR:
		num_str = num_str.substr(0, len(num_str)-1)
	else:
		den_str = den_str.substr(0, len(den_str)-1)
	update_display()
	
func clear_answer():
	if current_selected == SELECTED.NUMERATOR:
		num_str = ""
	else:
		den_str = ""
	update_display()
	
func change_sign():
	var new_str: String
	if current_selected == SELECTED.NUMERATOR:
		new_str = num_str
	else:
		new_str = den_str
	
	if new_str != "":
		if new_str[0] == "-":
			new_str = new_str.substr(1, len(new_str))
		else:
			new_str = "-" + new_str
		
	update_display()

func get_answer() -> String:
	return num_str + "/" + den_str
