extends CalculFrac

class_name FracMul

func _init(f1, f2, diff, type, st = -1).(f1, f2, diff, type, st):
	result = mul_frac(f1, f2)

static func mul_frac(f1, f2):
	var a = f1.numerator
	var b = f1.denominator
	var c = f2.numerator
	var d = f2.denominator
	
	return Fraction.new(a*c, b*d)


	
func _to_string() -> String:
	return str(self.f1) + "+" + str(self.f2)
	
func get_str_show() -> String:
	return str(self.f1) + " + " + str(self.f2)
