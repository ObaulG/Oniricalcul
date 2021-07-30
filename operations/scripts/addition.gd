extends Calcul

class_name Addition

var nb_numeral
var nb_carryover

func _init(nb1, nb2, diff, type, st = -1).(nb1, nb2, diff, type, st):
	self.result = nb1 + nb2
	nb_numeral = len(str(max(nb1,nb2)))
	
func to_string() -> String:
	return "Addition: "+ str(self.nb1) + "+" + str(self.nb2)
	
func get_str_show() -> String:
	return str(self.nb1) + " + " + str(self.nb2)
	
func determine_nb_carryover() -> void:
	var total = 0
	var retenue = false
	var a = self.nb1
	var b = self.nb2
	if b > a:
		a = self.nb2
		b = self.nb1
	for n in range(nb_numeral):
		var chiffre_a = int((a / pow(10,n))) % 10
		var chiffre_b = int((b / pow(10,n))) % 10
		retenue = (1 if retenue else 0) + chiffre_a + chiffre_b > 9
		total += (1 if retenue else 0)
	nb_carryover = total
	

func get_nb_numeral() -> int:
	return nb_numeral
	
func get_nb_carryover() -> int:
	return nb_carryover


