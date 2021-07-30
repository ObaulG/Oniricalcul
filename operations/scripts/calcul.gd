extends Operation

class_name Calcul
	
var nb1 = null
var nb2 = null

func _init(nb1, nb2, diff, type, st = -1).(diff, type, st):
	self.nb1 = nb1
	self.nb2 = nb2

func get_diff():
	return self.diff
	
func get_parameters() -> Array:
	return [nb1, nb2, subtype]
