extends Operation


class_name Calcul_1O
	
var nb1 = null

func _init(nb1, diff, type, st = -1).(diff, type, st):
	self.nb1 = nb1

func get_diff():
	return self.diff
	
func get_parameters() -> Array:
	return [nb1]

