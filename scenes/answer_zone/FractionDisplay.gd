extends Control

class_name FractionDisplay

export(int) var separation = 1
onready var lb_numerator: NumberLine = $VBoxContainer/CenterContainer/numerator
onready var lb_denominator: NumberLine = $VBoxContainer/CenterContainer2/denominator
onready var line: Line2D = $separator

export(int) var numerator
export(int) var denominator

func _ready():
	numerator = 1
	denominator = 1

func update_numerator(num: int):
	var str_num = str(num)
	if len(str_num) > max(len(str(numerator)), len(str(denominator))):
		#writing size might change, and position
		#of the line and denominator too
		var text_size: Vector2 = lb_numerator.lb_number.get("custom_fonts/font").get_string_size(str_num)
		print("text_size: " + str(text_size))
		line.clear_points()
		var y = text_size.y + separation
		line.add_point(Vector2(0, 0))
		line.add_point(Vector2(text_size.x+28, 0))
		
	numerator = num
	lb_numerator.update_number(numerator)
	
func update_denominator(den: int):
	var str_den = str(den)
	if len(str_den) > max(len(str(numerator)), len(str(denominator))):
		#writing size might change, and position
		#of the line and denominator too
		var text_size: Vector2 = lb_denominator.lb_number.get("custom_fonts/font").get_string_size(str_den)
		line.clear_points()
		var y = text_size.y + separation
		line.add_point(Vector2(0, 0))
		line.add_point(Vector2(text_size.x+28, 0))
		
	denominator = den
	lb_denominator.update_number(denominator)
	

