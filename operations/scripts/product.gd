extends Calcul


class_name Product

var nb_numeral


func _init(nb1, nb2, diff, type, st = -1).(nb1, nb2, diff, type, st):
	self.result = nb1 * nb2
	
func _to_string() -> String:
	return str(self.nb1) + "x" + str(self.nb2)
	
func get_str_show() -> String:
	return str(self.nb1) + " * " + str(self.nb2)
	
