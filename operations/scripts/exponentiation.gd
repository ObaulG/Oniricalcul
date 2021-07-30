extends Calcul_1O

class_name Exponentiation

var power: int

func _init(nb1, b, diff, type, st = -1).(nb1, diff, type, st):
	power = b
	self.result = pow(int(nb1), b)

func to_string() -> String:
	return "Exponentiation: " + str(nb1) + "^" + str(power)

func get_str_show() -> String:
	return str(nb1) + "^" + str(power)


