extends Calcul_1O

class_name RootOP

var power

func _init(nb1, p, diff, type, st = -1).(nb1, diff, type, st):
	power = p
	self.result = int(pow(nb1, p))

func to_string() -> String:
	return "Racine: " + str(power) + "rt(" + str(nb1) + ")"

func get_str_show() -> String:
	return str(nb1) + "^(1/" + str(power) + ")"

