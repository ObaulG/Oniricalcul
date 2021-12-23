extends Node

class_name Spellbook

enum BUYING_OP_ATTEMPT_RESULT{
	CAN_BUY = 1, 
	NO_SPACE, 
	NO_MONEY,
	ALREADY_BUYING, 
	ERROR}

signal good_answer(gid)
signal wrong_answer(gid)
signal operation_to_display_has_changed(gid, new_op)
signal incantation_has_changed(gid, L)
signal new_incantation_charged(gid)
signal incantation_progress_changed(gid, new_value)
signal money_value_has_changed(gid, n)
signal low_incantation_stock(gid)
signal meteor_invocation(gid, dico_threat)
signal defense_command(gid, power)
signal potential_value_changed(gid, x)
signal defense_power_changed(gid, x)
signal chain_value_changed(gid, n)

#Consts
const STANCES = {ATTACK = 1, DEFENSE = 2, BONUS = 3}
const THREAT_TYPES = {REGULAR = 1, FAST = 2, STRONG = 3}

var game_id
var character
var rng
var stance
var atk_type
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
var meteor_sent: int
var threat_count: int

#the threat with least remaining time

#nb of new operations generated between 2 rounds.
var operation_production: int
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
	pass
	
	
func initialise(char_dico):
	waiting_transaction = false
	game_id = get_parent().game_id
	rng = get_parent().rng
	
	character = char_dico["id"]
	atk_power = char_dico["threat_power"]
	atk_type = char_dico["threat_type"]
	atk_hp = char_dico["threat_hp"]
	malus_level = char_dico["malus_level"]
	inspiration = char_dico["inspiration"]
	operation_preference = char_dico["operations_preference"]
	difficulty_preference = char_dico["difficulty_preference"]
	operation_production = char_dico["operation_production"]
	
	money = 0
	money_per_round = 60
	meteor_sent = 0

	chain = 0
	nb_pattern_loops = 0

	threat_count = 0
	points = 0
	energy = 0
	stance = STANCES.ATTACK
	defense_power = ReliquatNumber.new(0)

	pattern = Pattern.new()
	pattern.connect("incantation_has_changed", self, "_on_incantation_change")
	pattern.set_elements(char_dico["base_pattern"])
	
	list_shop_operations = []
	operations = []
	operations_stock = []
	determine_defense_power()

	base_swap_price = 5
	base_erase_price = 7
	
	swap_price = base_swap_price
	erase_price = base_erase_price

func determine_defense_power():
	defense_power.set_value(7 + 0.18*determine_effective_power() )
	print("new defense power " + str(defense_power.get_value()))
	emit_signal("defense_power_changed", game_id, defense_power.get_value())
	
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
	var effective_potential = determine_effective_power()
	var power = determine_threat_power(effective_potential)
	var delay_time = determine_threat_delay_time(effective_potential)
	var hp = determine_threat_hp(effective_potential)
	var atk_side_effects = []
	
	return [power, delay_time, hp, atk_side_effects]

func determine_effective_power() -> int:
	var power = pattern.get_power()
	print("base potential " + str(power))
	var coeff = 1
	var bonus_potential = 0
	
	print("chain " + str(chain))
	print("character id" + str(character))
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
	if character == 1:
		coeff += float(min(chain, 20)) / 100.0
#	power = power * fit_coeff
	
	print("coeff " + str(coeff))
	print("flat bonus " + str(bonus_potential))
	
	power = power * coeff + bonus_potential
	print("effective potential used " + str(power))
	power = stepify(power, 0.01)
	emit_signal("potential_value_changed", game_id, power)
	return power
	
func new_round():
	swap_price += 3
	erase_price += 5
	earn_money(money_per_round)
	
func spend_money(n: int):
	money = clamp(money-n, 0, money)
	emit_signal("money_value_has_changed", game_id, money)
	
func earn_money(n: int):
	money += n
	emit_signal("money_value_has_changed", game_id, money)
	
func set_money_value(n: int):
	money = n
	
func get_potential():
	return pattern.get_power(0, true)
	
func get_defense_power():
	return defense_power.get_value()
	
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
	
	print("Incantation stored: " + str(len(operations_stock)))
	
	if len(operations) == 0:
		charge_new_incantation()
		
func charge_new_incantation():
	var new_incantation = operations_stock.pop_front()
	if len(operations_stock) < 3:
		emit_signal("low_incantation_stock", game_id)
		
	#what if there wasn't any new incantation in the stock??
	if new_incantation:
		operations = new_incantation
		print("domain " + str(game_id) + ": new incantation charged!")
		emit_signal("new_incantation_charged", game_id)
		emit_signal("operation_to_display_has_changed", game_id, get_current_operation())
		
func answer_response(good_answer):
	if good_answer:
		good_answer()
		print("good answer")
	else:
		wrong_answer()
		print("wrong_answer")
	determine_defense_power()
	emit_signal("chain_value_changed", game_id, chain)
	emit_signal("operation_to_display_has_changed", game_id, get_current_operation())
	
func generate_threat_data_dict() -> Dictionary:
	#[power, delay_time, hp, atk_side_effects]
	var threat_stats = determine_threat_stats(pattern.get_power())
	var dico_threat = {
		meteor_id = meteor_sent,
		hp = threat_stats[2],
		type = atk_type,
		power = threat_stats[0],
		delay = threat_stats[1],
		side_effects = threat_stats[3],
		sender = game_id
	}
	meteor_sent += 1
	return dico_threat
	
func good_answer():
	var current_pattern_el = get_current_pattern_element()
	get_parent().score_points(global.get_op_power_by_obj(current_pattern_el))
	chain += 1

	var is_incantation_completed = pattern.next()
	if is_incantation_completed:
		print("Spellbook of domain " + str(game_id) + ": Incantation completed!")
		print("Current stance: " + str(stance))
		match(stance):
			1:
				var dico_threat = generate_threat_data_dict()
				emit_signal("meteor_invocation", game_id, dico_threat)
			2:
				#var defense_damage = 0.5* (1 + (defense_power.apply() / pattern.get_len()))
				var defense_damage = defense_power.apply()
				emit_signal("defense_command", game_id, defense_damage)
			3:
				pass
		charge_new_incantation()
	
	emit_signal("incantation_progress_changed", game_id, pattern.get_index())
	
func wrong_answer():
	emit_signal("wrong_answer")
	chain = 0
	var progression_removal = 0
	match(malus_level):
		1:
			progression_removal = 0
		2:
			progression_removal = 1
		3:
			progression_removal = 10
			charge_new_incantation()
		4:
			progression_removal = 10
			charge_new_incantation()
	pattern.reverse_gear(progression_removal)

	emit_signal("incantation_progress_changed", game_id, pattern.get_index())

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
	
func get_inspiration():
	return inspiration
	
func get_waiting_transaction():
	return waiting_transaction

func get_operation_preference():
	return operation_preference
	
func get_operation_production():
	return operation_production
	
func get_difficulty_preference():
	return difficulty_preference
	
func set_stance(new_stance):
	print("new stance: " + str(new_stance))
	stance = new_stance
	
func _on_incantation_change():
	print("Player " + str(game_id) + ": incantation change !")
	emit_signal("incantation_has_changed", game_id, pattern.get_list())
	emit_signal("potential_value_changed", game_id, get_potential())
	determine_defense_power()
	
	#because the incantation has changed, we must destroy all
	#operation lists and generate new ones
	operations.clear()
	operations_stock.clear()
	
	#and replace the index to 0 to avoid messy situations
	pattern.reverse_gear(10)
	
	emit_signal("low_incantation_stock", game_id)

func _on_changing_stance_command(new_stance):
	set_stance(new_stance)
