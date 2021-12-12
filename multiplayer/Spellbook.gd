extends Node

class_name Spellbook
enum BUYING_OP_ATTEMPT_RESULT{
	CAN_BUY = 1, 
	NO_SPACE, 
	NO_MONEY,
	ALREADY_BUYING, 
	ERROR}
	
signal attack()
signal good_answer()
signal wrong_answer()
signal incantation_has_changed(L)
signal incantation_progress_changed(new_value)
signal money_value_has_changed(n)

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
#nb of new operations from enemies
var inspiration: int
var list_shop_operations: Array
var money: int
var money_per_round: int
var base_swap_price: int
var swap_price: int
var base_erase_price: int
var erase_price: int

#flag indicating if we have sent a shop request to the server
#without the answer (to prevent multiple buying)
var waiting_transaction: bool

var operations_generator: Calcul_Factory
var operations_stats: Array

#list of operations to answer, generated by calcul_generator
var operations: Array

# contains lists of operations to answer. Clients
# should always have one spare list to avoid waiting
# if they need another one to be generated
var operations_stock : Array

var points: int
var energy
var nb_calculs: int
var good_answers: int
var chain: int
var nb_pattern_loops: int

#onready var domain_field = get_parent().get_parent().get_node("domain_field")

func _ready():
	connect("changing_stance_command", self, "_on_changing_stance_command")
	
	
func initialise(char_dico):
	waiting_transaction = false
	rng = get_parent().rng
	
	atk_power = char_dico["threat_power"]
	atk_type = char_dico["threat_type"]
	atk_hp = char_dico["threat_hp"]
	malus_level = char_dico["malus_level"]
	inspiration = char_dico["inspiration"]
	meteor_sent = 0

	chain = 0
	nb_pattern_loops = 0

	threat_count = 0
	points = 0
	energy = 0
	chain = 0
	stance = STANCES.ATTACK
	defense_power = ReliquatNumber.new(0)

	pattern = Pattern.new()
	pattern.set_elements(char_dico["base_pattern"])
	pattern.connect("incantation_has_changed", self, "_on_incantation_change")
	list_shop_operations = []
	operations = []
	operations_stock = []
	determine_defense_power(pattern.get_power())

	base_swap_price = 5
	base_erase_price = 7
	
	swap_price = base_swap_price
	erase_price = base_erase_price
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
	
func new_round():
	swap_price += 3
	erase_price += 5
	earn_money(money_per_round)
	
func spend_money(n: int):
	money = clamp(money-n, 0, money)
	emit_signal("money_value_has_changed", money)
	
func earn_money(n: int):
	money += n
	emit_signal("money_value_has_changed", money)
	
func get_current_operation():
	return operations[pattern.get_index()]

func get_current_pattern_element():
	return pattern.get_current_element()
	
func on_change_stance_command(new_stance):
	stance = new_stance
	
#L is a list of incantations
func store_new_incantations(L: Array):
	for incantation in L:
		operations_stock.append(incantation)
	
func charge_new_incantation():
	var new_incantation = operations_stock.pop_front()
	if len(operations_stock) < 3:
		emit_signal("low_incantation_stock")
	#what if there wasn't any new incantation in the stock??
	if new_incantation:
		operations = new_incantation
	
func _on_domain_answer_response(id_domain, good_answer):
	if id_domain == get_parent().id_domain:
		if good_answer:
			good_answer()
		else:
			wrong_answer()
			
func good_answer():
	var is_incantation_completed = pattern.next()
	if is_incantation_completed:
		match(stance):
			STANCES.ATTACK:
				var dico_threat = {
					hp = atk_hp,
					type = atk_type,
					power = atk_power,
					delay = atk_delay_time,
					side_effects = []
				}
				emit_signal("meteor_invocation", dico_threat)
			STANCES.DEFENSE:
				determine_defense_power(pattern.get_power())
				var defense_damage = 0.5* (1 + (defense_power.apply() / pattern.get_len()))
				emit_signal("defense_command", defense_damage)
			STANCES.BONUS:
				pass
	emit_signal("incantation_progress_changed", pattern.get_index())
	
func wrong_answer():
	emit_signal("wrong_answer")
	var progression_removal = 0
	match(malus_level):
		1:
			progression_removal = 0
		2:
			progression_removal = 1
		3:
			progression_removal = 1
		4:
			progression_removal = 10
	pattern.reverse_gear(progression_removal)
	emit_signal("incantation_progress_changed", pattern.get_index())

func buy_attempt_result(action_type, price: int):
	if price <= money:
		if action_type == BonusMenuBis.BONUS_ACTION.BUY_OPERATION:
			if pattern.get_len() < 8:
				return BUYING_OP_ATTEMPT_RESULT.CAN_BUY
			else:
				return BUYING_OP_ATTEMPT_RESULT.NO_SPACE
		return BUYING_OP_ATTEMPT_RESULT.CAN_BUY
	else:
		return BUYING_OP_ATTEMPT_RESULT.NO_MONEY
		
func get_money():
	return money

func get_swap_price():
	return swap_price
	
func get_erase_price():
	return erase_price
	
func get_waiting_transaction():
	return waiting_transaction

func set_stance(new_stance):
	stance = new_stance
	
func _on_incantation_change():
	emit_signal("incantation_has_changed", pattern.get_list())
