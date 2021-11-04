extends Node

class_name BaseDomainData

#Spellbook : gestion of pattern progression and sending magic projectiles
onready var spellbook = $Spellbook
#InputHandler : calls functions located here
onready var input_handler = $InputHandler
#OperationStats : node storing all data from the player
onready var op_stats = $OperationStats
#Threats : node handling threat logic
onready var threats = $Threats
#smth else ?


#Signals
signal hp_value_changed(new_value)
signal damaged(n)
signal healed(n)
signal points_earned(n)


#Enums
enum BUYING_OP_ATTEMPT_RESULT{FREE_SPACE, NO_SPACE, NO_MONEY, ERROR}

#Consts
const STANCES = {ATTACK = 1, DEFENSE = 2, BONUS = 3}
const THREAT_TYPES = {REGULAR = 1, FAST = 2, STRONG = 3}

#Exported vars

#Public vars

#Private 
var id_domain
var id_character: int

var rng = RandomNumberGenerator.new()
var current_seed = rng.seed

var game_state: int
var game_time: float
var answer_time: float

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

func _ready():
	id_character = Gamestate.player_info["id_character_selected"]
	var char_dico = global.characters[id_character]
	hp_max = char_dico["hp"]
	hp_current = hp_max

	answer_time = 0.0
	game_time = 0.0
	
	points = 0
	nb_calculs = 0
	good_answers = 0
	chain = 0
	nb_pattern_loops = 0
	
	spellbook.initialize(char_dico)
	#input_handler.initialize()
	op_stats.initialize(char_dico)
