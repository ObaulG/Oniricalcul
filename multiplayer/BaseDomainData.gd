extends Node

class_name BaseDomainData

#Spellbook : gestion of pattern progression and sending magic projectiles
onready var spellbook = $Spellbook
#InputHandler : calls functions located here
#onready var input_handler = $InputHandler
#OperationStats : node storing all data from the player
onready var op_stats = $OperationStats
#smth else ?
onready var shopping_data = $ShoppingData

#Signals
signal hp_value_changed(gid, new_value)
signal damaged(gid, n)
signal healed(gid, n)
signal points_value_changed(gid, n)
signal eliminated(gid)
signal good_answers_value_changed(gid, n)
#Enums
enum BUYING_OP_ATTEMPT_RESULT{CAN_BUY=1, NO_SPACE, NO_MONEY, ERROR}

#Consts
const STANCES = {ATTACK = 1, DEFENSE = 2, BONUS = 3}
const THREAT_TYPES = {REGULAR = 1, FAST = 2, STRONG = 3}

#Exported vars

#Public vars

#Private 
var game_id
var id_character: int

var rng = RandomNumberGenerator.new()
var current_seed = rng.seed

var game_state: int
var game_time: float
var answer_time: float

var eliminated: bool
var hp_current: int
var hp_max: int

var points: int
var nb_calculs: int
var good_answers: int
var chain: int
var nb_pattern_loops: int

func process(delta):
	if game_state == 1:
		answer_time += delta
		game_time += delta

func _ready():
	spellbook.connect("wrong_answer", self, "on_spellbook_wrong_answer")
	id_character = -1
	eliminated = false
	
func initialise(char_id: int, pid: int):
	var char_dico = global.characters[char_id]
	game_id = pid
	id_character = char_id
	hp_max = char_dico["hp"]
	hp_current = hp_max
	emit_signal("hp_value_changed", game_id, hp_current)
	answer_time = 0.0
	game_time = 0.0
	
	points = 0
	nb_calculs = 0
	good_answers = 0
	chain = 0
	nb_pattern_loops = 0
	
	spellbook.initialise(char_dico)
	#input_handler.initialize()
	#op_stats.initialise(char_dico)


func get_damage(n):
	hp_current = clamp(hp_current - n, 0, hp_max)
	print("damages: " + str(n))
	emit_signal("damaged", game_id, n)
	emit_signal("hp_value_changed", game_id, hp_current)
	if hp_current <= 0:
		eliminated = true
		emit_signal("eliminated", game_id)
		
func heal(n):
	hp_current = clamp(hp_current + n, 0, hp_max)
	emit_signal("healed", game_id, n)
	emit_signal("hp_value_changed", game_id, hp_current)

func score_points(n: int):
	points += n
	emit_signal("points_value_changed", game_id, points)
	
func answer_response(good_answer):
	spellbook.answer_response(good_answer)
	if good_answer:
		good_answers += 1
		emit_signal("good_answers_value_changed", game_id, good_answers)
		
func is_alive():
	return hp_current <= 0

# getters
func get_id_domain():
	return game_id

func get_id_character():
	return id_character

func get_hp():
	return hp_current
	
func get_hp_max():
	return hp_max
	
func get_points():
	return points

func get_nb_calculs():
	return nb_calculs

func get_good_answers():
	return good_answers
	
func get_chain():
	return chain
	
func get_nb_pattern_loops():
	return nb_pattern_loops
	
func get_answer_time():
	return answer_time

func get_money():
	return spellbook.get_money()
	
func get_swap_price():
	return spellbook.get_swap_price()
	
func get_erase_price():
	return spellbook.get_erase_price()
	

# setters
func set_shop_operations(op_list: Array):
	spellbook.list_shop_operations = op_list.duplicate()

func set_hp_value(hp: int):
	hp_current = hp
	if hp_current <= 0:
		eliminated = true
		emit_signal("eliminated", game_id)
		
func on_spellbook_wrong_answer():
	if id_character == 1:
		get_damage(1)
