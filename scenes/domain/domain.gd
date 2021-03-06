extends Node

const INCANTATIONS = {ATTACK = 1, DEFENSE = 2, BONUS = 3}
const THREAT_TYPES = {REGULAR = 1, FAST = 2, STRONG = 3}
enum BUYING_OP_ATTEMPT_RESULT{FREE_SPACE, NO_SPACE, NO_MONEY, ERROR}

var threat = global.threat

signal attack(character, threat_type, atk_hp, power, delay, side_effects)
signal end(id_domain)
signal new_money_value(money)
signal first_threat_ref_changed()
class_name Domain

var id_domain: int

#player node
var player: Player

#character (contains some base stats)
var character: Character
onready var char_icon = $margin_c/vboxc/main_data/char/char_icon

#base difficulty (maybe to remove?) 
var base_diff: int

#custom object to store the list of operation types
var pattern: Pattern

# coeff of pattern fitting character conditions.
# values between 0 and 1
var fit_coeff: float

var hp_current: int
var hp_max: int
var hp_bar: HealthDisplay

#incantation value
var stance: int
var stance_label: Label

var meteor_sent: int
#attack stats
var atk_type: int

#might be deleted
var atk_speed
var atk_cd
var atk_power
var atk_hp
var atk_delay_time
var atk_progress

var defense_power: ReliquatNumber
#shield points (not used)
var shield: int

#list of bonus for the game
#{bonus_id: quantity}
var bonus: Dictionary

#node used to show threats on screen
var terrain: PanelContainer


var malus_level: int
#nb of new operations generated between 2 rounds.
var nb_new_operations: int
var money: int
var money_per_round: int
var base_swap_price: int
var swap_price: int
var base_erase_price: int
var erase_price: int
var operation_preference: Dictionary
var difficulty_preference: Dictionary
var operations_generator: Calcul_Factory
var operations_stats: Array
#list of operations to answer, generated by calcul_generator
var operations: Array

#reference of the threat with least remaining time
var first_threat: Threat
var threat_count: int

var points: int
var points_label: Label

# counts the remainder of rounding potential 
# when incantations are completed
var reliquat: float

var energy
var energy_label: Label
var nb_calculs: int
var nb_calculs_label: Label
var power_label: Label
var good_answers: int
var good_answers_label: Label
var time_calcul: float
var time_calcul_label: Label
var chain: int
var chain_label: Label
var nb_pattern_loops: int

var rng = RandomNumberGenerator.new()
var current_seed = rng.seed

var black_blanco_bonus: bool

var base_projectile_start: Vector2
onready var collision_zone_to_enemy = $margin_c/vboxc/hbox2/Terrain/A2D_send_meteor

var main_game_node
func create(main_game_node,id, player, contract, character_id = 5):
	self.main_game_node = main_game_node
	self.id_domain = id
	self.player = player

	meteor_sent = 0
	var char_dico = global.characters[character_id]
	self.character = Character.new(char_dico)
	
	operations_generator = Calcul_Factory.new()
	nb_new_operations = 2
	operation_preference = character.get_operation_preference()
	difficulty_preference = character.get_difficulty_preference()
	
	hp_current = char_dico["hp"]
	hp_max = hp_current
	
	hp_bar = $margin_c/vboxc/main_data/VBoxContainer/hp_bar
	hp_bar.set_max(hp_max)
	hp_bar.update_healthbar(hp_max)
	
	shield = 0
	base_diff = char_dico["difficulty"]
	pattern = Pattern.new([], char_dico["base_scaling_value"])
	for op in char_dico["base_pattern"]:
		pattern.append(op)
	generate_operations()
	pattern.power_evaluation()
	nb_calculs = 0
	nb_calculs_label = $margin_c/vboxc/hbox2/vbox/total_operations
	good_answers = 0
	good_answers_label = $margin_c/vboxc/hbox2/vbox/right_answers
	time_calcul = 0.0
	time_calcul_label = $margin_c/vboxc/hbox2/vbox/speed_answer
	atk_speed = char_dico["atk_speed"]
	atk_cd = 1.0/atk_speed
	atk_power = char_dico["threat_power"]
	atk_type = char_dico["threat_type"]
	atk_hp = char_dico["threat_hp"]
	malus_level = char_dico["malus_level"]
	terrain = $margin_c/vboxc/hbox2/Terrain
	points_label = $margin_c/vboxc/hbox2/vbox/points
	chain_label = $margin_c/vboxc/hbox2/vbox/chain
	power_label = $margin_c/vboxc/hbox2/vbox/power
	#energy_label = $MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer/energy

	bonus = {}
	first_threat = null
	threat_count = 0
	points = 0
	energy = 0
	chain = 0
	stance = INCANTATIONS.ATTACK
	stance_label = $margin_c/vboxc/hbox2/vbox/stance
	
	atk_progress = $margin_c/vboxc/main_data/VBoxContainer/CenterContainer/incantation_progress
	var tex = character.get_icon_texture()
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
	
	fit_coeff = 1
	
	var size = terrain.rect_size
	var width = size[0]
	var height = size[1]
	base_projectile_start = Vector2(width/2,height)
	
	if id_domain == 2:
		collision_zone_to_enemy.position = Vector2(-15, -15)

func _process(dt):
	pass

func random_int_rounding(x: float) -> int:
	var difference = x - int(x)
	var n = int(x)
	if difference > 0 and rng.randf() < difference:
		n += 1
	return n
	
func determine_defense_power(potential: int):
	defense_power.set_value(7 + 0.18*potential )
	
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
	
	if 8 in bonus.keys():
		potential += 38
	
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
	
func update_threat_stats():
	var potential = pattern.get_power()
	var effective_potential = round(potential + reliquat)
	reliquat = potential + reliquat - effective_potential

	atk_power = determine_threat_power(effective_potential)
	atk_delay_time = determine_threat_delay_time(effective_potential)
	atk_hp = determine_threat_hp(effective_potential)
	var atk_side_effects = []
	
	
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
	fit_coeff = coeff
	
func determine_effective_power() -> int:
	var power = pattern.get_power()
	var bonus_keys = bonus.keys()
	if 12 in bonus_keys:
		power += 8*bonus[12]
	if 11 in bonus_keys:
		power += 5*bonus[11]
	if 10 in bonus_keys:
		power += 3*bonus[10]
	if 6 in bonus_keys:
		power *= 1.3
	if 5 in bonus_keys:
		power *= 1.2
	if 3 in bonus_keys:
		power *= (1 + 0.05*get_nb_threats())
	if 0 in bonus_keys:
		power *= 1.1
	if character.get_id() == 1:
		power = power * (1 + max(chain, 20)/100 )
	power = power * fit_coeff
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
		print("Prochaine cible d??termin??e: " + str(first_threat.get_id()))
	else:
		print("Aucune cible trouv??e...")
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
	 
func create_magic_homing_projectile(target, start_pos: Vector2, power):
	print("Projectile cr???? en " + str(start_pos))
	var new_projectile = global.projectile.instance()
	new_projectile.create(self, power, character.get_id(), id_domain, target)
	terrain.add_child(new_projectile)
	new_projectile.position = start_pos
func attack_enemy(potential: float, fraction=1.0):
	print("ATTACK")
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
	emit_signal("attack", attack_data)
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
	if shield > 0:
		shield = max(0,shield-n)
	else:
		hp_current = max(0, hp_current - n)
	hp_bar.update_healthbar(hp_current)
	
	if hp_current == 0:
		emit_signal("end", id_domain)
		
func receive_threat(dico_threat):
	print("M??t??orite re??ue")
	# R??cup??ration des param??tres
	var hp = dico_threat["atk_hp"]
	var id = dico_threat["threat_id"]
	var sender_character = dico_threat["character"]
	var type = dico_threat["threat_type"]
	var power = dico_threat["power"]
	var delay = dico_threat["delay"]
	var side_effects = dico_threat["side_effects"]
	
	#La taille d??pend de la puissance
	var scaling = power / 4.0
	
	var position = Vector2(rng.randi_range(20,200), 50)
	# vitesses en px/s
	var x_speed = 0
	var y_speed = 380.0 / delay 
	
	var meteor = threat.instance()
	
	terrain.add_child(meteor)
	meteor.create(id, hp, type, power, delay, self, x_speed, y_speed)
	meteor.position = position
	meteor.apply_scale(Vector2(scaling, scaling))
	meteor.set_texture(global.threat_texture)
	
	change_magic_projectiles_target()
func update_energy_label():
	energy_label.text = "Energie: " + str(energy)

func _on_threat_impact(threat_type, hp_current, power):
	receive_damage(power)
	determine_nearest_threat()

func _on_threat_destroyed(threat_type, power, id_character, over_damage, position):
	print("Une m??t??orite a ??t?? d??truite.")
	determine_nearest_threat()

func _on_projectile_target_not_found(power):
	var power_fraction = power/defense_power.get_value()
	attack_enemy(get_base_potential() * power_fraction)
	
func change_magic_projectiles_target():
	if threat_presence():
		for child in terrain.get_children():
			if child is MagicProjectile:
				child.change_target(first_threat)

func sustain_hp(n):
	hp_current = min(hp_current + n, hp_max)

func check_answer(value, answer_time: float):
	time_calcul += answer_time
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
		
	chain_label.text = "Cha??ne: " + str(chain)
	nb_calculs_label.text = "Calculs: " + str(nb_calculs)
	good_answers_label.text = "% juste: " + str(100*good_answers/nb_calculs)
	
	if time_calcul != 0:
		time_calcul_label.text = str(good_answers/time_calcul)

	operations_stats.append(stat_calcul)

func threat_presence():
	return threat_count > 0

func update_atk_progress():
	atk_progress.value = pattern.get_index() * 100 / pattern.get_len()

func right_answer(op: Operation):
	good_answers += 1
	chain += 1
	points += op.get_potential()
	points_label.text = "Points: " + str(points)
	var incantation_completed = pattern.next()
	update_atk_progress()
	if not incantation_completed:
		if stance == INCANTATIONS.DEFENSE:
			attack_threat()
	else:
		var effective_power = determine_effective_power()
		if stance == INCANTATIONS.ATTACK:
			attack_enemy(effective_power)
		elif stance == INCANTATIONS.DEFENSE:
			attack_threat(true)
		elif stance == INCANTATIONS.BONUS:
			apply_bonus()
		generate_operations()
	
func wrong_answer(calcul):
	print("R??ponse incorrecte")
	if black_blanco_bonus:
		black_blanco_bonus = false
	else:
		chain = 0
		var effective_malus_level = malus_level
		if 13 in bonus.keys():
			effective_malus_level = min(0,malus_level - 1)
			
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
				if character.get_id() != 1:
					#special animation ?
					receive_damage(1)
	chain = 0
	update_atk_progress()
	if character.get_id() == 1:
		receive_damage(1)
		
func pass_answer():
	chain = 0
	
func generate_operations():
	var op_list = pattern.get_list()
	
	if 7 in bonus.keys() and len(op_list) > 2:
		op_list[2][1] = max(5, op_list[2][1] + bonus[7])
		
	if 8 in bonus.keys() and len(op_list) > 0:
		op_list[0][1] = min(1, op_list[0][1] - bonus[8])
		
	if 2 in bonus.keys() and len(op_list) > 0:
		op_list[-1][1] = max(5, op_list[-1][1] + bonus[2])
		
	operations = []
	for op in op_list:
		operations.append(operations_generator.generate(op))

func can_erase_operation() -> bool:
	return money >= erase_price
	
func can_swap_operations() -> bool:
	return money >= swap_price
	
func is_incanting() -> bool:
	return pattern.get_index() == 0
	
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
	
func get_operation_preference():
	return character.get_operation_preference()
	
func get_difficulty_preference():
	return character.get_difficulty_preference()
	
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
	
func get_bonus_dict() -> Dictionary:
	return bonus
	
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


func set_money(value: int):
	money = value
	
func add_bonus(bonus_id: int):
	if bonus_id in bonus.keys():
		bonus[bonus_id] += 1
	else:
		bonus[bonus_id] = 1
		
func spend_money(value: int):
	assert (value <= money)
	money -= value
	print("Argent d??pens??")
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
		
func set_stance(type):
	stance = type
	var texte = "Atq"
	if type == INCANTATIONS.DEFENSE:
		texte = "Def"
	elif type == INCANTATIONS.BONUS:
		texte = "Bns"
	stance_label.text = "Position: " + texte
	
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



func _on_A2D_send_meteor_body_entered(body):
	pass # Replace with function body.
