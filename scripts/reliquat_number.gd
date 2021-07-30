extends Object

class_name ReliquatNumber

# Classe composée d'un nombre, arrondi à 10^(-p) près, et d'un reliquat.
# Utilité: appliquer la valeur arrondie du nombre tout en gardant le reste
# (le reliquat) pour plus tard, par exemple pour un calcul de dégâts.

# Ex: une attaque inflige 100.5 dégâts, mais le jeu ne tient compte que des
# entiers. L'attaque inflige en réalité 100 dégâts, et les 0.5 sont stockés.
# Le coup suivant inflige alors 100.5 + 0.5 = 101 dégâts, et le reliquat devient
# maintenant 0.


var value: float
var reliquat: float
var p: int

func _init(v = 0, precision = 0):
	value = v
	reliquat = 0
	self.p = precision


func apply(bonus = 0.0):
	var temp = stepify((value + bonus) + reliquat, p)
	reliquat = (value + bonus) + reliquat - temp
	return temp

func get_value():
	return value
	
func get_reliquat():
	return reliquat
	
func get_precision():
	return p
	
func set_value(new_n):
	value = new_n
	
func set_reliquat(new_r):
	reliquat = new_r
	
func set_precision(new_p):
	p = new_p
	
