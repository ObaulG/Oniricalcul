extends Node

class_name Spellbook

#Consts
const STANCES = {ATTACK = 1, DEFENSE = 2, BONUS = 3}
const THREAT_TYPES = {REGULAR = 1, FAST = 2, STRONG = 3}

var rng
var stance: int
var atk_type: int
var atk_speed
var atk_cd
var atk_power
var atk_hp
var atk_delay_time

var malus_level: int
var operation_preference: Dictionary
var difficulty_preference: Dictionary

#custom object to store the list of operation types
var pattern: Pattern
# counts the remainder of rounding potential 
# when STANCES are completed
var reliquat: float

var defense_power: ReliquatNumber
var meteor_sent := 0
var threat_count: int

#the threat with least remaining time

#nb of new operations generated between 2 rounds.
var nb_new_operations: int
var money: int
var money_per_round: int
var base_swap_price: int
var swap_price: int
var base_erase_price: int
var erase_price: int

var operations_generator: Calcul_Factory
var operations_stats: Array
#list of operations to answer, generated by calcul_generator
var operations: Array

var points: int
var energy
var nb_calculs: int
var good_answers: int
var chain: int
var nb_pattern_loops: int

onready var threats = get_parent().get_node("Threats")
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func initialise(char_dico):
	rng = get_parent().rng
	
	atk_power = char_dico["threat_power"]
	atk_type = char_dico["threat_type"]
	atk_hp = char_dico["threat_hp"]
	malus_level = char_dico["malus_level"]
	meteor_sent = 0

	chain = 0
	nb_pattern_loops = 0

	threat_count = 0
	points = 0
	energy = 0
	chain = 0
	stance = STANCES.ATTACK
	defense_power = ReliquatNumber.new(0)

	determine_defense_power(pattern.get_power())

func determine_defense_power(potential: int):
	defense_power.set_value(7 + 0.18*potential )
	
func random_int_rounding(x: float) -> int:
	var difference = x - int(x)
	var n = int(x)
	if difference > 0 and rng.randf() < difference:
		n += 1
	return n
	
func determine_threat_power(potential: int) -> int:
	var power = 0
	if atk_type == THREAT_TYPES.REGULAR:
		power = 0.82 + 0.06 * potential
	elif atk_type == THREAT_TYPES.FAST:
		power = 1 + 0.008 * potential
	elif atk_type == THREAT_TYPES.STRONG:
		power = 7.46 + 0.18 * potential
	
	power = random_int_rounding(power)
	return power

func determine_threat_delay_time(potential: int) -> float:
	var time = 10
	
	if atk_type == THREAT_TYPES.REGULAR:
		time = 8.12 - 0.04 * potential
	elif atk_type == THREAT_TYPES.FAST:
		time = 3.024 - 0.008 * potential
	elif atk_type == THREAT_TYPES.STRONG:
		time = 32.24 - 0.08 * potential
		
	return time
	
func determine_threat_hp(potential: int) -> int:
	var hp = 1
	if atk_type == THREAT_TYPES.REGULAR:
		hp = 0.85 + 0.05 * potential
	elif atk_type == THREAT_TYPES.FAST:
		hp = 0.94 + 0.02 * potential
	elif atk_type == THREAT_TYPES.STRONG:
		hp = 15.55 + 0.15 * potential
		
	hp = random_int_rounding(hp)
	return hp
	
func determine_threat_stats(potential: float):
	var power = determine_threat_power(potential)
	var delay_time = determine_threat_delay_time(potential)
	var hp = determine_threat_hp(potential)
	var atk_side_effects = []
	
	return [power, delay_time, hp, atk_side_effects]

func determine_effective_power() -> int:
	var power = pattern.get_power()
	
#	var bonus_keys = bonus.keys()
#	if 12 in bonus_keys:
#		power += 8*bonus[12]
#	if 11 in bonus_keys:
#		power += 5*bonus[11]
#	if 10 in bonus_keys:
#		power += 3*bonus[10]
#	if 6 in bonus_keys:
#		power *= 1.3
#	if 5 in bonus_keys:
#		power *= 1.2
#	if 3 in bonus_keys:
#		power *= (1 + 0.05*get_nb_threats())
#	if 0 in bonus_keys:
#		power *= 1.1
	if get_parent().id_character == 1:
		power = power * (1 + max(chain, 20)/100 )
#	power = power * fit_coeff
	power = round(power)

	return power

func attack_threat(incantation_completed = false):
	threats.determine_nearest_threat()
	
	if threats.threat_presence() :
		var damages = 0.5*defense_power.apply() / pattern.get_len()
		if incantation_completed:
			damages += 0.5*defense_power.apply()
		create_magic_homing_projectile(threats.get_first_threat(), 
										base_projectile_start, 
										damages)
	else:
		apply_bonus(true)
	 
sync func create_magic_homing_projectile(target, start_pos: Vector2, power):
	var new_projectile = global.projectile.instance()
	new_projectile.create(self, power, id_character, id_domain, target)
	terrain.add_child(new_projectile)
	new_projectile.position = start_pos
	
func attack_enemy(potential: float, fraction=1.0):
	var threat_stats = determine_threat_stats(potential) 
	update_threat_stats()
	var attack_data = {
		character = self.character,
		atk_type = self.atk_type,
		threat_hp = self.atk_hp,
		threat_power = self.atk_power,
		threat_delay = self.atk_delay_time,
		id = meteor_sent
	}
	main_field_node.meteor_send(id_domain, attack_data)
	meteor_sent += 1
