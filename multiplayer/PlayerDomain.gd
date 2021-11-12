class_name PlayerDomain
extends Node

#the instance of player in the "world"
#we must add the operation zone because
#it's supposed to be private, and sending
#data with rpc to the main field
#about writing a number would be useless

#the operation zone should have a max size
#to leave room for the other player's domain

# an operation is abstract (already done), but
# the ui should be abstract too
# because some operations need a different display
# (fractions for instance)
const STANCES = {ATTACK = 1, DEFENSE = 2, BONUS = 3}
const THREAT_TYPES = {REGULAR = 1, FAST = 2, STRONG = 3}
const keypad_numbers = [48,49,50,51,52,53,54,55,56,57]
const numpad_numbers = [KEY_KP_0,KEY_KP_1,KEY_KP_2,KEY_KP_3,KEY_KP_4,KEY_KP_5,KEY_KP_6,KEY_KP_7,KEY_KP_8,KEY_KP_9]

#Signals
signal attack(character, threat_type, atk_hp, power, delay, side_effects)
signal end(id_domain)
signal new_money_value(money)
signal first_threat_ref_changed()

#Enums
enum BUYING_OP_ATTEMPT_RESULT{FREE_SPACE, NO_SPACE, NO_MONEY, ERROR}



#Exported vars

#Public vars

#Private 

var id_domain
var rng = RandomNumberGenerator.new()
var current_seed = rng.seed

var id_character: int

var game_state: int
var game_time: float
var answer_time: float
var hp_current: int
var hp_max: int

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
var black_blanco_bonus: bool
var meteor_sent := 0
var threat_count: int

#the threat with least remaining time
var first_threat: Threat

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

var base_projectile_start: Vector2


#Onready vars
onready var main_field_node = get_parent()

onready var char_icon = $margin_c/vboxc/main_data/char/char_icon
onready var hp_bar = $margin_c/vboxc/main_data/VBoxContainer/hp_bar
onready var stance_display = $margin_c/vboxc/hbox2/vbox/stance
onready var points_label = $margin_c/vboxc/hbox2/vbox/points
onready var chain_label = $margin_c/vboxc/hbox2/vbox/chain
onready var power_label = $margin_c/vboxc/hbox2/vbox/power

onready var nb_calculs_label = $margin_c/vboxc/hbox2/vbox/total_operations
onready var good_answers_label = $margin_c/vboxc/hbox2/vbox/right_answers
onready var time_calcul_label = $margin_c/vboxc/hbox2/vbox/speed_answer

onready var atk_progress = $margin_c/vboxc/main_data/VBoxContainer/CenterContainer/incantation_progress

onready var terrain = $margin_c/vboxc/hbox2/Terrain

onready var collision_zone_to_enemy = $margin_c/vboxc/hbox2/Terrain/A2D_send_meteor

#these are labels (might change later)
onready var operation_display = $vbox/operation_zone/VBoxContainer/operation_display
onready var operation_answer = $vbox/operation_zone/VBoxContainer/operation_answer

onready var game_timer = $game_timer
#Functions


func create(id_char):
	# given by server?
	# id_domain = ???
	
	id_character = id_char
	var char_dico = global.characters[id_character]
	hp_max = char_dico["hp"]
	hp_current = hp_max
	hp_bar.set_max(hp_max)
	
	pattern_initialization(char_dico)
	
	atk_power = char_dico["threat_power"]
	atk_type = char_dico["threat_type"]
	atk_hp = char_dico["threat_hp"]
	malus_level = char_dico["malus_level"]
	
	meteor_sent = 0
	
	nb_calculs = 0
	good_answers = 0
	answer_time = 0.0
	game_time = 0.0
	chain = 0
	nb_pattern_loops = 0
	
	first_threat = null
	threat_count = 0
	points = 0
	energy = 0
	chain = 0
	stance = STANCES.ATTACK
	
	var tex = global.char_data[id_character].get_icon_texture()
	char_icon.texture = global.get_resized_ImageTexture(tex, 192, 192)
	defense_power = ReliquatNumber.new(0)
	money = 0
	money_per_round = 100
	base_erase_price = 3
	erase_price = 3
	base_swap_price = 3
	swap_price = 3
	black_blanco_bonus = false
	determine_defense_power(pattern.get_power())
	
	var size = terrain.rect_size
	var width = size[0]
	var height = size[1]
	base_projectile_start = Vector2(width/2,height)
	
	if id_domain == 2:
		collision_zone_to_enemy.position = Vector2(-15, -15)
	
func process(delta):
	answer_time += delta
	if (is_network_master()):
		pass
	else:
		pass
		
#Entrée du joueur
func _input(event):
	if game_state == 1:
		if event.is_action("delete_char") && event.is_pressed() && !event.is_echo():
			operation_answer.text = operation_answer.text.left(operation_answer.text.length()-1)
			
		if event.is_action("validate") && event.is_pressed() && !event.is_echo():
			check_answer(operation_answer)

		if event.is_action("attack_stance") && event.is_pressed() && !event.is_echo():
			update_stance(STANCES.ATTACK)
			
		if event.is_action("defense_stance") && event.is_pressed() && !event.is_echo():
			update_stance(STANCES.DEFENSE)
			
		if event.is_action("bonus_stance") && event.is_pressed() && !event.is_echo():
			update_stance(STANCES.ATTACK)
			
		if event is InputEventKey and event.pressed:			
			if event.scancode == keypad_numbers[0] or event.scancode == numpad_numbers[0]:
				operation_answer.text += '0'
			elif event.scancode == keypad_numbers[1] or event.scancode == numpad_numbers[1]:
				operation_answer.text += '1'
			elif event.scancode == keypad_numbers[2] or event.scancode == numpad_numbers[2]:
				operation_answer.text += '2'
			elif event.scancode == keypad_numbers[3] or event.scancode == numpad_numbers[3]:
				operation_answer.text += '3'
			elif event.scancode == keypad_numbers[4] or event.scancode == numpad_numbers[4]:
				operation_answer.text += '4'
			elif event.scancode == keypad_numbers[5] or event.scancode == numpad_numbers[5]:
				operation_answer.text += '5'
			elif event.scancode == keypad_numbers[6] or event.scancode == numpad_numbers[6]:
				operation_answer.text += '6'
			elif event.scancode == keypad_numbers[7] or event.scancode == numpad_numbers[7]:
				operation_answer.text += '7'
			elif event.scancode == keypad_numbers[8] or event.scancode == numpad_numbers[8]:
				operation_answer.text += '8'
			elif event.scancode == keypad_numbers[9] or event.scancode == numpad_numbers[9]:
				operation_answer.text += '9'

func check_answer(value):
	nb_calculs += 1
	var op = operations[pattern.get_index()]
	
	var stat_calcul = [
		op.get_type(),
		op.get_diff(),
		op.get_parameters(),
		answer_time,
		value, 
		true, #correct answer
	]
		
	if op.is_result(value):
		right_answer(op)
	else:
		wrong_answer(op)
		stat_calcul[5] = false
		
	chain_label.text = "Chaîne: " + str(chain)
	nb_calculs_label.text = "Calculs: " + str(nb_calculs)
	good_answers_label.text = "% juste: " + str(100*good_answers/nb_calculs)
	
	if game_time != 0.0:
		time_calcul_label.text = str(good_answers/game_time)

	operations_stats.append(stat_calcul)
	
	operation_answer.text = ""

func generate_operations():
	var op_list = pattern.get_list()
	operations = []
	for op in op_list:
		operations.append(operations_generator.generate(op))
		
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
	
func determine_character_conditions_fit_coeff():
	var coeff = 1.0
#	match character.get_id():
#		1:
#			for op in pattern.get_list():
#				if op.get_diff() > 1:
#					coeff = coeff / 1.05
#		2:
#			pass
#		3:
#			var list = pattern.get_list()
#			for op in list:
#				if op.get_diff() > 2:
#					coeff = coeff / 1.05
#
#			if list[-1].get_diff < 3:
#				coeff = coeff / 1.5
#		4:
#			pass
#		5:
#			pass
	return coeff
	
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
	if id_character == 1:
		power = power * (1 + max(chain, 20)/100 )
#	power = power * fit_coeff
	power = round(power)
	power_label.text = "Puissance: " + str(power)
	return power
	
func determine_nearest_threat():
	var min_time = 999
	var time = null
	var count = 0
	for child in terrain.get_children():
		if child is Threat:
			if not child.is_dead():
				count += 1
				time = child.get_remaining_time()
				if time < min_time:
					first_threat = child
					min_time = time
	threat_count = count
	
	if is_instance_valid(first_threat):
		print("Prochaine cible déterminée: " + str(first_threat.get_id()))
	else:
		print("Aucune cible trouvée...")
	emit_signal("first_threat_ref_changed")
	
func attack_threat(incantation_completed = false):
	determine_nearest_threat()
	
	if threat_presence() :
		var damages = 0.5*defense_power.apply() / pattern.get_len()
		if incantation_completed:
			damages += 0.5*defense_power.apply()
		create_magic_homing_projectile(first_threat, 
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
	
func apply_bonus(no_threat_defense = false):
	var potential = pattern.get_power()
	
func time_stop():
	for child in terrain.get_children():
		if child is Threat:
			child.freeze()
	
func resume():
	for child in terrain.get_children():
		if child is Threat:
			child.unfreeze()

func hp_current_get():
	return hp_current
	
func receive_damage(n):
	hp_current = max(0, hp_current - n)
	update_hp(hp_current)
	if hp_current == 0:
		emit_signal("end", id_domain)
		
func receive_threat(dico_threat):
	print("Météorite reçue")
	# Récupération des paramètres
	var hp = dico_threat["atk_hp"]
	var id = dico_threat["threat_id"]
	var sender_character = dico_threat["character"]
	var type = dico_threat["threat_type"]
	var power = dico_threat["power"]
	var delay = dico_threat["delay"]
	var side_effects = dico_threat["side_effects"]
	
	#La taille dépend de la puissance
	var scaling = power / 4.0
	
	var position = Vector2(rng.randi_range(20,200), 50)
	# vitesses en px/s
	var x_speed = 0
	var y_speed = 380.0 / delay 
	
	var meteor = global.threat.instance()
	
	terrain.add_child(meteor)
	meteor.create(id, hp, type, power, delay, self, x_speed, y_speed)
	meteor.position = position
	meteor.apply_scale(Vector2(scaling, scaling))
	meteor.set_texture(global.threat_texture)
	
	change_magic_projectiles_target()
	
func change_magic_projectiles_target():
	if threat_presence():
		for child in terrain.get_children():
			if child is MagicProjectile:
				child.change_target(first_threat)

func sustain_hp(n):
	update_hp(min(hp_current + n, hp_max))

func threat_presence():
	return threat_count > 0

func pass_answer():
	chain = 0

func get_least_powerful_op():
	var list = pattern.get_list()
	var mini = 0
	var mini_v = global.get_op_power_by_obj(list[0])
	for i in range(1,len(list)):
		var v = global.get_op_power_by_obj(list[i])
		if v < mini:
			mini = i
			mini_v = v
	return list[mini]

#func add_bonus(bonus_id: int):
#	if bonus_id in bonus.keys():
#		bonus[bonus_id] += 1
#	else:
#		bonus[bonus_id] = 1
		
func spend_money(value: int):
	assert (value <= money)
	money -= value
	print("Argent dépensé")
	emit_signal("new_money_value", money)
	
func earn_money(value: int):
	money += value
	emit_signal("new_money_value", money)
	
func buying_operation_attempt(value: int):
	if value < money:
		if pattern.get_len() < 8:
			return BUYING_OP_ATTEMPT_RESULT.FREE_SPACE
		else:
			return BUYING_OP_ATTEMPT_RESULT.NO_SPACE
	else:
		return BUYING_OP_ATTEMPT_RESULT.NO_MONEY
		
func new_operation(id: int, diff: int, value: int, index = -1):
	spend_money(value)
	if index > -1:
		pattern.add_to([id, diff], index)
	else:
		pattern.append([id, diff])
	generate_operations()
	update_atk_progress()
	
func erase_operation(index: int):
	spend_money(erase_price)
	pattern.remove(index)
	generate_operations()
	# if the player has a n-operation incantation, at n-2 index and deletes 1 op
	# then the game would crash because the incantation would be complete
	# without answering, so he has to answer a new operation. Nice try!
	# (maybe for a future mechanic?)
	if pattern.get_index() == pattern.get_len():
		pattern.reverse_gear(1)
	update_atk_progress()
	
func buying_bonus(bonus_id: int, value: int) -> bool:
	if value < money:
		money -= value
		return true
	else:
		return false

func upgrading_stat(stat_id: int, value: int) -> bool:
	if value < money:
		money -= value
		return true
	else:
		return false


func update_threat_stats():
	var potential = pattern.get_power()
	var effective_potential = round(potential + reliquat)
	reliquat = potential + reliquat - effective_potential

	atk_power = determine_threat_power(effective_potential)
	atk_delay_time = determine_threat_delay_time(effective_potential)
	atk_hp = determine_threat_hp(effective_potential)
	var atk_side_effects = []
	
#Helpers
func pattern_initialization(char_dico: Dictionary):
	pattern = Pattern.new([], char_dico["base_scaling_value"])
	for op in char_dico["base_pattern"]:
		pattern.append(op)
	#generate_operations()
	pattern.power_evaluation()
	
func right_answer(op: Operation):
	good_answers += 1
	chain += 1
	points += op.get_potential()
	points_label.text = "Points: " + str(points)
	var incantation_completed = pattern.next()
	update_atk_progress()
	if not incantation_completed:
		if stance == STANCES.DEFENSE:
			attack_threat()
	else:
		var effective_power = determine_effective_power()
		if stance == STANCES.ATTACK:
			attack_enemy(effective_power)
		elif stance == STANCES.DEFENSE:
			attack_threat(true)
		elif stance == STANCES.BONUS:
			apply_bonus()
		generate_operations()
	
func wrong_answer(calcul):
	print("Réponse incorrecte")
	if black_blanco_bonus:
		black_blanco_bonus = false
	else:
		chain = 0
		var effective_malus_level = malus_level
		
#		if 13 in bonus.keys():
#			effective_malus_level = min(0,malus_level - 1)
			
		match(effective_malus_level):
			0:
				pass
			1:
				pattern.reverse_gear(1)
			2:
				pattern.reverse_gear(10)
			3:
				pattern.reverse_gear(10)
				generate_operations()
			4:
				pattern.reverse_gear(10)
				generate_operations()
				#char 1 can't receive twice the damage from his malus
				if id_character != 1:
					#special animation ?
					receive_damage(1)
	chain = 0
	update_atk_progress()
	if id_character == 1:
		receive_damage(1)

func can_erase_operation() -> bool:
	return money >= erase_price
	
func can_swap_operations() -> bool:
	return money >= swap_price
	
func is_incanting() -> bool:
	return pattern.get_index() == 0
	
#Getters/Setters
func get_collision_zone_to_enemy():
	return collision_zone_to_enemy
	
func get_current_calcul():
	var index = pattern.get_index()
	return operations[index]
	
func get_current_pattern_element():
	return pattern.get_current_op()
	
func get_pattern():
	return pattern.get_list()
	
func get_base_potential():
	return pattern.get_power(0, true)

func get_nb_new_operations():
	return nb_new_operations
	
func get_money():
	return money
	
func get_nb_calculs():
	return nb_calculs
	
func get_good_answers():
	return good_answers
	
func get_erase_price():
	return erase_price
	
func get_swap_price():
	return swap_price
	
func get_nearest_threat():
	return first_threat
func get_nb_threats() -> int:
	var n = 0
	for child in terrain.get_children():
		if child is Threat:
			n += 1
	return n
func get_total_hp_threats() -> int:
	var total = 0
	for child in terrain.get_children():
		if child is Threat:
			total += child.get_hp()
	return total
	
func get_defense_power():
	return defense_power.get_value()
	
func get_operations_stats():
	return operations_stats
	
func get_most_powerful_op():
	var list = pattern.get_list()
	var maxi = 0
	var maxi_v = global.get_op_power_by_obj(list[0])
	for i in range(1,len(list)):
		var v = global.get_op_power_by_obj(list[i])
		if v > maxi:
			maxi = i
			maxi_v = v
	return list[maxi]

	
func set_money(value: int):
	money = value
	
# UI Update
sync func update_atk_progress():
	atk_progress.value = pattern.get_index() * 100 / pattern.get_len()
	
sync func update_hp(new_value):
	hp_current = new_value
	hp_bar.update_value(new_value)
	
sync func update_stance(stance):
	self.stance = stance
	var text = "ATK"
	if stance == STANCES.DEFENSE:
		text = "DEF"
	if stance == STANCES.BONUS:
		text = "BNS"
	stance_display.text = text
	
#Event handlers
func _on_GameMaster_send_threat(sender_id, target_id, dico_threat):
	if target_id == id_domain:
		receive_threat(dico_threat)

func _on_GameMaster_resume():
	resume()

func _on_GameMaster_pause():
	time_stop()

func _on_GameMaster_shopping_time():
	earn_money(money_per_round)

func _on_GameMaster_new_round():
	erase_price += 3
	swap_price += 2

func _on_threat_impact(threat_type, hp_current, power):
	receive_damage(power)
	determine_nearest_threat()

func _on_threat_destroyed(threat_type, power, id_character, over_damage, position):
	print("Une météorite a été détruite.")
	determine_nearest_threat()

func _on_projectile_target_not_found(power):
	var power_fraction = power/defense_power.get_value()
	attack_enemy(get_base_potential() * power_fraction)


func _on_GameFieldMulti_domain_answer_response(id, good_answer):
	if id == id_domain:
		if good_answer:
			pass
		else:
			pass
