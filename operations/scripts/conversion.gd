extends Operation

class_name Conversion

var start_base
var start_number
var final_base


func _init(start_base, start_number, final_base, diff, type, subtype).(diff, type, subtype):
	self.start_base = start_base
	self.start_number = start_number
	self.final_base = final_base
	
	self.result = 0
	if self.start_base == 10:
		self.result = convert_decimal_to_other_base(self.start_number, self.final_base)
	else:
		if self.final_base == 10:
			self.result = convert_to_decimal(self.start_number, self.final_base)
		else:
			self.result = convert_baseA_baseB(self.start_number, self.start_base, self.final_base)

func convert_to_decimal(n: String, base: int) -> String:
	var total = 0
	var power = 1
	var i = len(n) - 1
	while i > 0:
		total = total + power*int(n[i])
		power = power * base
		i -= 1
	return str(total)
	
func convert_decimal_to_other_base(n: int, base: int) -> String:
	var new_number = ""
	#Divisions successives
	while n > 0:
		new_number = str(n%base) + new_number
		n = int(n/base)
	return new_number
	
func convert_baseA_baseB(n: String, A: int, B: int) -> String:
	if A == 10:
		return convert_decimal_to_other_base(int(n),B)
	elif B == 10:
		return convert_to_decimal(n, B)
	else:
		return convert_decimal_to_other_base(int(convert_to_decimal(n, A)), B)
		
func to_string() -> String:
	return str(start_number) + "("+str(start_base)+") ->..."+"("+str(final_base)+")"
	
func get_str_show() -> String:
	return str(start_number) + "("+str(start_base)+") ->..."+"("+str(final_base)+")"
	
func get_operands() -> Array:
	return [self.start_base, self.start_number, self.final_base]
	
func get_parameters() -> Array:
	return [start_base, start_number, final_base]

