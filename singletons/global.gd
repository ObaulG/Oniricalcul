extends Node

enum GAME_MODES{
	CLASSIC,
	VERSUS,
}
#Données de jeu
var game_mode = 0
var continues = 2

var last_played = null



var player

var current_dialog
#id of character selected in char select
var character = -1
var enemy_character = -1
#diff selected in char select
var diff = 0

var sprite_sheet_operations = load("res://textures/operations/spritesheet.png")
var SOUND_ID = {
	1: load("res://sound/sfx-blipmale.wav"),
	2: load("res://sound/sfx-blipfemale.wav"),
	3: load("res://sound/sfx-dramapound.wav"),
}
var text = {
	1: {"fr": "Choisissez votre personnage",
		"en": "Choose your character"},
	2: {"fr": "Personnage choisi : ",
		"en": "Choosen character : "}
}

# Textures
var threat_texture = load("res://textures/meteor.jpg")
var threat = load("res://scenes/threat/threat.tscn")
var unknown = load("res://textures/unknown.png")

var projectile = load("res://scenes/magic_projectile/MagicProjectile.tscn")
var bar_red = load("res://textures/barHorizontal_red.png")
var bar_green = load("res://textures/barHorizontal_green.png")
var bar_yellow = load("res://textures/barHorizontal_yellow.png")

var bonus = load("res://bonus/bonus.tscn")
var operation_display = load("res://operations/displaying/operation_display.tscn")
var character_display = load("res://scenes/character_display/CharacterDisplay.tscn")
# Bonus
var BONUS = [
	{"id": 0,
	 "name": "Stylo du maître",
	 "effect": "Augmente le potentiel de 10%.",
	 "effect_fast": "Pot. +",
	 "descr": "Placebo ++",
	 "unique": true,
	 "rarity": 2,},
	{"id": 1,
	 "name": "Dofus Emeraude",
	 "effect": "Augmente les PV max de 6. Rend 6 PV à chaque interlude.",
	 "effect_fast": "PVmax. +6",
	 "descr": "Issu d'un autre univers. Augmente la vitalite.",
	 "unique": true,
	 "rarity": 5,},
	{"id": 2,
	 "name": "Quatre étoiles",
	 "effect": "Augmente la difficulté du dernier calcul de 1.",
	 "effect_fast": "Diff+",
	 "descr": "Exercice d'approfondissement, dont la résolution est laissée au lecteur.",
	 "unique": false,
	 "rarity": 1,},
	{"id": 3,
	 "name": "Choc d'adrénaline",
	 "effect": "Augmente le potentiel d'attaque de 5% par menace sur le domaine. Chaque opération d'incantation d'attaque correcte applique également une défense.",
	 "effect_fast": "Danger->Att. ++",
	 "descr": "",
	 "unique": true,
	 "rarity": 38,},
	{"id": 4,
	 "name": "Valet de Coeur",
	 "effect": "Augmente les PV max de 4.",
	 "effect_fast": "Pvmax. +4",
	 "descr": "80 coeur. ",
	 "unique": true,
	 "rarity": 1,},
	{"id": 5,
	 "name": "Pile V+",
	 "effect": "Augmente le potentiel de 20%.",
	 "effect_fast": "Pot. ++",
	 "descr": "Mais où sont elles cachées?",
	 "unique": true,
	 "rarity": 5,},
	{"id": 6,
	 "name": "Crayon Critique",
	 "effect": "Augmente le potentiel de 30%. En cas d'erreur, l'incantation est renouvelée et -1 PV.",
	 "effect_fast": "Pot. +++",
	 "descr": "Un crayon aiguisé. Ne pas appuyer trop fort en réflechissant",
	 "unique": true,
	 "rarity": 4,},
	{"id": 7,
	 "name": "Livre d'exercices",
	 "effect": "Augmente la difficulté du troisième calcul de 1",
	 "effect_fast": "Diff+",
	 "descr": "15 exercices par page, c'est beaucoup trop.",
	 "unique": false,
	 "rarity": 1,},
	{"id": 8,
	 "name": "Activité d'introduction",
	 "effect": "Réduit la difficulté du premier calcul de 1.",
	 "effect_fast": "Diff-",
	 "descr": "Un échauffement pour mieux apprendre.",
	 "unique": false,
	 "rarity": 1,},
	{"id": 9,
	 "name": "Blanco noir",
	 "effect": "En cas de mauvaise réponse, annule tout effet négatif. (1x par incantation)",
	 "effect_fast": "Tol+",
	 "descr": "Il devrait s'appeler autrement mais on n'a pas d'idée.",
	 "unique": true,
	 "rarity": 3,},
	{"id": 9,
	 "name": "Accélérateur gravitationnel",
	 "effect": "Augmente le potentiel de 38 pour le calcul du temps d'impact des menaces.",
	 "effect_fast": "Vit.++",
	 "descr": "Multiplie par 2 le champ de gravité.",
	 "unique": true,
	 "rarity": 5,},
	{"id": 10,
	 "name": "Stylo bleu",
	 "effect": "Augmente le potentiel de 3.",
	 "effect_fast": "Pot. +",
	 "descr": "Le capuchon est un peu machouillé...",
	 "unique": false,
	 "rarity": 1,},
	{"id": 11,
	 "name": "Stylo vert",
	 "effect": "Augmente le potentiel de 5.",
	 "effect_fast": "Pot. +",
	 "descr": "Le capuchon est un peu machouillé...",
	 "unique": false,
	 "rarity": 1,},
	{"id": 12,
	 "name": "Stylo rouge",
	 "effect": "Augmente le potentiel de 8.",
	 "effect_fast": "Pot. +",
	 "descr": "Le capuchon est un peu machouillé...",
	 "unique": false,
	 "rarity": 1,},
	{"id": 13,
	 "name": "Feuilles de brouillon",
	 "effect": "Réduit le malus d'erreur de 1",
	 "effect_fast": "Malus ---",
	 "descr": "Elles ne seront pas rendues avec la copie. ",
	 "unique": true,
	 "rarity": 5,},
]
const PATH = {
	"OPERATIONS_JSON": "res://operations/operation_data.json",
	"OPERATIONS_ATLAS": "res://textures/operations/spritesheet.png",
	"SAVE_FILE": "res://save/savegame.save",
	"ACHIEVEMENTS": "res://save/achievements.json",
	"DIALOG": "res://scenes/dialog/Dialog.json",
}
# Informations sur les personnages. A convertir en JSON un jour
const characters = {
  1: {
	"id": 1,
	"name": "Nério",
	"icon_path": "res://textures/xenio2.png",
	"descr": {
	  "fr": "L'enfant des étoiles. Capable d'invoquer des météorites, ce qui est un comble vu ce qui l'attend.",
	  "en": "The starchild. Can summon meteors, funny if we consider what he's going to experience."
	},
	"info": "Enchaîne les calculs simples. Bonus de puissance pour les réponses rapides et les longues chaînes de calculs justes, mais subit un malus important en cas d'erreur.",
	"supporting_spell": "",
	"supporting_spell-info": "",
	"malus_level": 4,
	"hp": 38,
	"difficulty": 3,
	"base_pattern": [[1, 1], [2, 1], [3, 1]],
	"operations_preference": {
		1: 4,
		2: 3,
		3: 3,
		4: 0,
	},
	"difficulty_preference": {
		1: 90,
		2: 10,
		3: 0,
		4: 0,
		5: 0,
	},
	"base_scaling_value": 5,
	"inspiration": 2,
	"atk_speed": 2,
	"threat_type": 1,
	"threat_power": 4,
	"threat_hp": 3,
	"threat_delay": 10,
	"energy_cost": 4,
  },
  2: {
	"id": 2,
	"name": "Rosaline",
	"icon_path": "res://textures/rosaline.png",
	"descr": {
	  "fr": "La divinité mineure. Cependant, elle est au même niveau qu'un humain dans le monde onirique.",
	  "en": "A minor goddess. But remains at human level in this oniric world."
	},
	"info": "Puissante en début de partie mais progresse moins que les autres.",
	"supporting_spell": "",
	"supporting_spell-info": "",
	"malus_level": 2,
	"hp": 51,
	"difficulty": 2,
	"base_pattern": [[1, 3], [3, 2], [3, 2]],
	"operations_preference": {
		1: 10,
		2: 25,
		3: 65,
		4: 0,
	},
	"difficulty_preference": {
		1: 20,
		2: 30,
		3: 25,
		4: 20,
		5: 5,
	},
	"base_scaling_value": 8,
	"inspiration": 5,
	"atk_speed": 0.25,
	"threat_type": 1,
	"threat_power": 18,
	"threat_hp": 26,
	"threat_delay": 10,
	"energy_cost": 18,
	},
  3: {
	"id": 3,
	"name": "???",
	"icon_path": "res://textures/xenio.png",
	"descr": {
	  "fr": "Son bras gauche est un grappin. On est bien dans un rêve",
	  "en": ""
	},
	"info": "Les incantations sont des séries de calculs simples qui se concluent par un calcul plus difficile.",
	"supporting_spell": "",
	"supporting_spell-info": "",
	"malus_level": 2,
	"hp": 24,
	"difficulty": 3,
	"base_pattern": [[1, 1], [2, 1], [3, 3]],
	"operations_preference": {
		1: 3,
		2: 3,
		3: 3,
		4: 1,
	},
	"difficulty_preference": {
		1: 35,
		2: 30,
		3: 20,
		4: 10,
		5: 5,
	},
	"base_scaling_value": 10,
	"inspiration": 4,
	"atk_speed": 1,
	"threat_type": 1,
	"threat_power": 12,
	"threat_hp": 15,
	"threat_delay": 15,
	"energy_cost": 15,
  },
  4: {
	"id": 4,
	"name": "Lina",
	"icon_path": "res://textures/lina2.png",
	"descr": {
	  "fr": "Elle est aveugle, mais ce n'est pas ce que remarquerez en premier.",
	  "en": "She's blind, but it's not the first thing you will notice first."
	},
	"info": "Enchaîne les calculs de difficulté moyenne. Un bonus est attribué si l'incantation est réalisée rapidement.",
	"supporting_spell": "",
	"supporting_spell-info": "",
	"malus_level": 3,
	"hp": 35,
	"difficulty": 4,
	"base_pattern": [[1, 2], [2, 2], [3, 2]],
	"operations_preference": {
		1: 2,
		2: 5,
		3: 3,
		4: 0,
	},
	"difficulty_preference": {
		1: 10,
		2: 40,
		3: 40,
		4: 9,
		5: 1,
	},
	"base_scaling_value": 9,
	"inspiration": 3,
	"atk_speed": 1,
	"threat_type": 1,
	"threat_power": 12,
	"threat_hp": 16,
	"threat_delay": 4,
	"energy_cost": 24,
  },
  5: {
	"id": 5,
	"name": "Viriel",
	"icon_path": "res://textures/viriel2.png",
	"descr": {
	  "fr": "Une autre beauté divine. ",
	  "en": "Another stunning beauty. "
	},
	"info": "Mélange de calculs simples et difficiles.",
	"supporting_spell": "",
	"supporting_spell-info": "",
	"malus_level": 3,
	"hp": 27,
	"difficulty": 1,
	"base_pattern": [[1, 2], [1, 2], [3, 1]],
	"operations_preference": {
		1: 3,
		2: 3,
		3: 4,
		4: 0,
	},
	"difficulty_preference": {
		1: 90,
		2: 10,
		3: 0,
		4: 0,
		5: 0,
	},
	"base_scaling_value": 15,
	"inspiration": 8,
	"atk_speed": 4,
	"threat_type": 1,
	"threat_power": 2,
	"threat_hp": 1,
	"threat_delay": 1,
	"energy_cost": 8,
  },
}

var achievements_dico: Dictionary
const OPERATIONS = {
	ADDITION = 1,
	SUBSTRACTION = 2,
	PRODUCT = 3,
	CONVERSION = 4,
}
const OP_ID = {
	1: OPERATIONS.ADDITION,
	2: OPERATIONS.SUBSTRACTION,
	3: OPERATIONS.PRODUCT,
	4: OPERATIONS.CONVERSION,
}


var char_data: Dictionary
var dialog_data: Dictionary
var op_atlas: AtlasTexture 
var lang = "fr"
var op_data: Dictionary
var time_played: float


func _init():
	
	# character data loading 
	for char_id in characters.keys():
		char_data[char_id] = Character.new(characters[char_id])
	# character spritesheets loading
	
	# retrieve operations data from json
	var file = File.new()
	var path = PATH["OPERATIONS_JSON"]
	file.open(path, file.READ)
	var textdata = file.get_as_text()
	file.close()
	var result_JSON = JSON.parse(textdata)
	if result_JSON.error != OK:
		print("[load_json_file] Error loading JSON file '" + path + "'.")
		print("\tError: ", result_JSON.error)
		print("\tError Line: ", result_JSON.error_line)
		print("\tError String: ", result_JSON.error_string)
	
	for op_dict in result_JSON.get_result()["operations"]:
		op_data[int(op_dict["id"])] = OperationData.new(op_dict)
		
	# operations textures loading
	op_atlas = AtlasTexture.new()
	op_atlas.set_atlas(load(PATH["OPERATIONS_ATLAS"]))
	op_atlas.set_region(Rect2(0,0,64,64))

	# loading achievements
	file = File.new()
	path = PATH["ACHIEVEMENTS"]
	file.open(path, file.READ)
	textdata = file.get_as_text()
	file.close()
	result_JSON = JSON.parse(textdata)
	if result_JSON.error != OK:
		print("[load_json_file] Error loading JSON file '" + path + "'.")
		print("\tError: ", result_JSON.error)
		print("\tError Line: ", result_JSON.error_line)
		print("\tError String: ", result_JSON.error_string)
		
	achievements_dico = result_JSON.get_result()

	#loading dialogs
	file = File.new()
	path = PATH["DIALOG"]
	file.open(path, file.READ)
	textdata = file.get_as_text()
	file.close()
	result_JSON = JSON.parse(textdata)
	if result_JSON.error != OK:
		print("[load_json_file] Error loading JSON file '" + path + "'.")
		print("\tError: ", result_JSON.error)
		print("\tError Line: ", result_JSON.error_line)
		print("\tError String: ", result_JSON.error_string)
		
	dialog_data = result_JSON.get_result()
	current_dialog = "null"
	
	load_game()
func _process(delta):
	time_played += delta
	
func get_resized_ImageTexture(t: Texture, w: int, h: int) -> Texture:
	var img = t.get_data()
	img.resize(w, h)
	var im_t = ImageTexture.new()
	im_t.create_from_image(img)
	return im_t
	
func load_game():
	player = Player.new()
	player.loadData(PATH["SAVE_FILE"])
	print(player)
	
func save_game():
	var save_file = File.new()
	save_file.open("user://savegame.save", File.WRITE)
	save_file.store_var(to_json(player.save(time_played)))
	save_file.close()

func set_game_settings(settings: Dictionary):
	global.character = settings["character_id"]
	global.enemy_character = settings["cpu_character_id"]
	global.diff = settings["hardness"]

func get_nb_continues():
	return player.get_continues()
	
func lose_continue():
	player.lose_continue()
	
func get_file_path(index):
	if str(index) in PATH:
		return PATH[index]
	else:
		return ""
		
func get_op_power(type: int, diff: int) -> int:
	return op_data[type].get_potential(diff)

func get_op_power_by_obj(values: Array) -> int:
	return op_data[values[0]].get_potential(values[1])

func get_dialog_line(id):
	return dialog_data["dialogue_lines"][str(id)][lang]
	
func get_dialog_tree(name: String):
	return dialog_data["dialogues"][name]
	
func get_char_name(id: int):
	return char_data[id].get_name()
#list is a list of element pattern ([type, diff])
func most_powerful_op(list: Array):
	var maxi = 0
	var maxi_v = global.get_op_power_by_obj(list[0])
	for i in range(1,len(list)):
		var v = global.get_op_power_by_obj(list[i])
		if v > maxi:
			maxi = i
			maxi_v = v
	return list[maxi]

func least_powerful_op(list: Array):
	var mini = 0
	var mini_v = global.get_op_power_by_obj(list[0])
	for i in range(1,len(list)):
		var v = global.get_op_power_by_obj(list[i])
		if v < mini:
			mini = i
			mini_v = v
	return list[mini]
	
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		save_game()
		get_tree().quit()
