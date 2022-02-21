extends Operation

class_name CalculFrac
	
var f1 = null
var f2 = null

func _init(f1, f2, diff, type, st = -1).(diff, type, st):
	self.f1 = f1
	self.f2 = f2

func get_diff():
	return self.diff
	
func get_operands() -> Array:
	return [self.f1, self.f2]

func get_parameters() -> Array:
	return [f1, f2, subtype]

