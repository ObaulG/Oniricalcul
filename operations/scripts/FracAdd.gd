extends CalculFrac

class_name FracAdd


func _init(f1, f2, diff, type, st = -1).(f1, f2, diff, type, st):
	pass

func add_frac(f1, f2):
	var a = f1.numerator
	var b = f1.denominator
	var c = f2.numerator
	var d = f2.denominator
	
	if b == d:
		return Fraction.new(a+c, b)
	else:
		var common_den = Math.ppcm(b, d)
		var coeffA = int(common_den/b)
		var coeffB = int(common_den/d)
		a *= coeffA
		b *= coeffA
		c *= coeffB
		d *= coeffB
		numerator += a+c
		return Fraction.new(numerator, common_den)
		
func _to_string() -> String:
	return str(self.f1) + "+" + str(self.f2)
	
func get_str_show() -> String:
	return str(self.f1) + " + " + str(self.f2)
