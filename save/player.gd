extends Object

class_name Player

var pseudo
var level
var experience

#Liste d'objets
var inventory

#Caractéristiques
var base_pattern
var base_power
var agility

#Equipements
var ring1
var ring2
var hat
var amulet
var cloak

#Trophées
var trophy1
var trophy2
var trophy3
var trophy4

var gametime
var timestamp_lastplayed

func _init(name = "CPU"):
	if !self.loadData():
		pseudo = name
		level = 1
		experience = 0
		inventory = []
		
		base_pattern = []
		ring1 = null
		ring2 = null
		hat = null
		amulet = null
		cloak = null
		
		trophy1 = null
		trophy2 = null
		trophy3 = null
		trophy4 = null
		
		gametime = 0
		timestamp_lastplayed = null
	
func loadData():
	pass
	
func save():
	var save_dict = {
		"pseudo": pseudo,
		"level": level,
		"experience": experience,
		"inventory": inventory,
		"base_pattern": base_pattern,
		"base_power": base_power,
		"agility": agility,
		"ring1": ring1,
		"ring2": ring2,
		"hat": hat,
		"amulet": amulet,
		"cloak": cloak,
		"trophy1": trophy1,
		"trophy2": trophy2,
		"trophy3": trophy3,
		"trophy4": trophy4,
		"gametime": 0,
		"timestamp_lastplayed": OS.get_unix_time()
	}
	return save_dict
