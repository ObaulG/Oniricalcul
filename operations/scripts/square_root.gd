extends Calcul_1O

class_name SquareRootOP

func _init(nb1, diff, type, st = -1).(nb1, diff, type, st):
	self.result = int(sqrt(nb1))

func to_string() -> String:
	return "Racine carrée: sqrt " + str(nb1)

func get_str_show() -> String:
	return "sqrt(" + str(nb1) + ""


