extends Node2D

signal send_threat(dico_threat, sender_id, target_id)

signal game_pause()
signal game_resume()
signal achievement(id)
signal shopping_time()
signal new_round()

const keypad_numbers = [48,49,50,51,52,53,54,55,56,57]
const numpad_numbers = [KEY_KP_0,KEY_KP_1,KEY_KP_2,KEY_KP_3,KEY_KP_4,KEY_KP_5,KEY_KP_6,KEY_KP_7,KEY_KP_8,KEY_KP_9]

const base_answer_time = 1.38
const BASE_NEW_OPERATIONS = 4

const AI_BASE_ANSWER_TIME_BY_DIFF = [4.0, 3.2, 2.4, 1.6, 1.2, 0.6]
const AI_BASE_ANSWER_TIME_BY_OP_DIFF = [0.05, 0.2, 1.2, 2.3, 4]
class_name GameMaster

var pre_round_duration: float
var round_duration: float
var shopping_duration: float

var ai_diff: int
var calcul_factory
var player1
var answer_time_p1 = 0
var answer_p1
var domain1: Domain
var current_calcul_label
var bonus_menu_p1
#Sera contrôlé par le CPU
var player2 
var answer_p2
var answer_time_p2
var domain2 
var cpu_speed
var timer_p2
var bonus_menu_p2
var bar_answering_p2
# 0: pré-jeu (3 secondes d'attente)
# 1: jeu en cours
# 2: pause
# 3: période d'achat
# 4: fin du jeu
var game_state = 0
var rng = RandomNumberGenerator.new()
var current_seed = rng.seed

var round_counter
var pre_game_timer
var shop_timer
var round_timer
var round_time_bar
var timer_node

func _ready():
	
	pre_round_duration = 1.0
	round_duration = 31.0
	shopping_duration = 10.0
	
	calcul_factory = Calcul_Factory.new()
	
	player1 = global.player
	answer_p1 = $window/game_elements/hbox/central_field/operation_zone/VBoxContainer/operation_answer
	answer_time_p1 = 0.0
	current_calcul_label = $window/game_elements/hbox/central_field/operation_zone/VBoxContainer/operation_display
	domain1 = $window/game_elements/hbox/p1_field/MarginContainer/domain_p1
	bonus_menu_p1 = $window/game_elements/CenterContainer/bonus_window/bonus_menu
	
	domain1.create(1, player1, null, global.character)
	player2 = Player.new()
	domain2 = $window/game_elements/hbox/p2_field/domain_p2
	domain2.create(2, player2, null, global.enemy_character)
	answer_time_p2 = 0.0
	
	pre_game_timer = $pre_game_timer
	round_timer = $round_timer
	shop_timer = $shop_timer

	timer_node = $window/game_elements/hbox/central_field/global_data/TimeDisplay
	timer_p2 = $window/game_elements/hbox/p2_field/p2_playing_timer
	bar_answering_p2 = $window/game_elements/hbox/p2_field/answer_time_ai/HBoxContainer/TimeDisplay
	bonus_menu_p2 = $window/game_elements/CenterContainer/bonus_window/bonus_menu2
	answer_p1.text = ""
	
	round_counter = 1
	ai_diff = global.diff
	bar_answering_p2.set_max(AI_BASE_ANSWER_TIME_BY_DIFF[ai_diff] + AI_BASE_ANSWER_TIME_BY_OP_DIFF[4])
	_on_shop_timer_timeout()
	show_calcul()
	
func _process(delta):
	
	var time_left
	if game_state == 0:
		time_left = pre_game_timer.get_time_left()
	if game_state == 1:
		answer_time_p1 += delta
		answer_time_p2 += delta
		
		time_left = round_timer.get_time_left()
		timer_node.update_time(time_left)
		
		var answer_time_ai_left = timer_p2.get_time_left()
		bar_answering_p2.update_time(answer_time_ai_left)
	if game_state == 3:
		time_left = shop_timer.get_time_left()
		bonus_menu_p1.set_time(time_left)
	
#Entrée du joueur
func _input(event):
	
	if game_state == 1:
		if event.is_action("delete_char") && event.is_pressed() && !event.is_echo():
			answer_p1.text = answer_p1.text.left(answer_p1.text.length()-1)
			
		if event.is_action("validate") && event.is_pressed() && !event.is_echo():
			print("Réponse validée")
			domain1.check_answer(answer_p1.text, answer_time_p1)
			answer_time_p1 = 0
			answer_p1.text = ""
			show_calcul()
			
		if event.is_action("attack_stance") && event.is_pressed() && !event.is_echo():
			domain1.set_stance(Domain.INCANTATIONS.ATTACK)
			
		if event.is_action("defense_stance") && event.is_pressed() && !event.is_echo():
			domain1.set_stance(Domain.INCANTATIONS.DEFENSE)
			
		if event.is_action("bonus_stance") && event.is_pressed() && !event.is_echo():
			domain1.set_stance(Domain.INCANTATIONS.ATTACK)
			
		if event is InputEventKey and event.pressed:
			print("Touche du clavier: ", event.scancode, " appuyée")
			
			if event.scancode == keypad_numbers[0] or event.scancode == numpad_numbers[0]:
				answer_p1.text += '0'
			elif event.scancode == keypad_numbers[1] or event.scancode == numpad_numbers[1]:
				answer_p1.text += '1'
			elif event.scancode == keypad_numbers[2] or event.scancode == numpad_numbers[2]:
				answer_p1.text += '2'
			elif event.scancode == keypad_numbers[3] or event.scancode == numpad_numbers[3]:
				answer_p1.text += '3'
			elif event.scancode == keypad_numbers[4] or event.scancode == numpad_numbers[4]:
				answer_p1.text += '4'
			elif event.scancode == keypad_numbers[5] or event.scancode == numpad_numbers[5]:
				answer_p1.text += '5'
			elif event.scancode == keypad_numbers[6] or event.scancode == numpad_numbers[6]:
				answer_p1.text += '6'
			elif event.scancode == keypad_numbers[7] or event.scancode == numpad_numbers[7]:
				answer_p1.text += '7'
			elif event.scancode == keypad_numbers[8] or event.scancode == numpad_numbers[8]:
				answer_p1.text += '8'
			elif event.scancode == keypad_numbers[9] or event.scancode == numpad_numbers[9]:
				answer_p1.text += '9'
		
func show_calcul():
	current_calcul_label.text = domain1.get_current_calcul().get_str_show()

func _on_domain_p1_attack(character, threat_type, atk_hp, power, delay, side_effects):
	print("Commande: envoi de la météorite au joueur 2")
	send_threat(1, 2, character, threat_type, atk_hp, power, delay, side_effects)


func _on_domain_p2_attack(character, threat_type, atk_hp, power, delay, side_effects):
	send_threat(2, 1, character, threat_type, atk_hp, power, delay, side_effects)

func send_threat(sender_id, target_id, character, threat_type, atk_hp, power, delay, side_effects):
	var dico_threat = {
		"character": character,
		"threat_type": threat_type,
		"atk_hp": atk_hp,
		"power": power,
		"delay": delay,
		"side_effects": side_effects,
	}

	emit_signal("send_threat", dico_threat, sender_id, target_id)

func _on_domain_end(id_domain):
	var text = "Victoire !"
	if id_domain == 1:
		text = "Défaite..."
		emit_signal("game_won")
	else:
		emit_signal("game_lost")
	$window/game_elements/end_label.text = text
	$window/game_elements/end_label.visible = true 
	
	get_tree().paused = true
	
	# looking for achievements
	var unlocked = player1.unlocked
	
	for achievement in global.achievements_dico["achievements"]:
		var id = achievement["id"]
		if not id in unlocked["achievements"]:
			match id:
				6:
					if ai_diff == 5 and domain1.get_nb_calculs() == domain1.get_good_answers():
						emit_signal("achievement", 6)

	var stats = domain1.get_operations_stats()
	
func determine_ai_time_to_answer():
	var op = domain2.get_current_pattern_element()
	var type = op[0]
	var diff = op[1]
	var answer_time = AI_BASE_ANSWER_TIME_BY_DIFF[ai_diff] + AI_BASE_ANSWER_TIME_BY_OP_DIFF[diff-1]
	timer_p2.start(answer_time)
	bar_answering_p2.set_max(answer_time)
	bar_answering_p2.update_time(answer_time)
	
#Called to make AI answer their operation
func _on_p2_playing_timer_timeout():
	
	if game_state == 1:
		var calcul = domain2.get_current_calcul()
		var result = calcul.get_result()
		print("Joueur 2 répond")
		
		var will_answer_right = true
		if rng.randf() > 0.98:
			will_answer_right = false
		
		if will_answer_right:
			domain2.check_answer(result, answer_time_p2)
		else:
			domain2.check_answer("0", answer_time_p2)
			
		answer_time_p2 = 0
		determine_ai_time_to_answer()
		
		if not domain2.is_incanting():
			var total_hp_threats = domain2.get_total_hp_threats()
			print("total hp " + str(total_hp_threats))
			print("defense power " + str(domain2.get_defense_power()))
			if total_hp_threats > domain2.get_defense_power():
				domain2.set_stance(Domain.INCANTATIONS.DEFENSE)
			else:
				domain2.set_stance(Domain.INCANTATIONS.ATTACK)
	
func ponderate_random_choice_dict(dict: Dictionary):
	#Returns a random key ponderated by numbers in [0,100[.
	#ex: with {"A": 40, "B": 60}, P(x=A) = 0.4 and P(x=B) = 0.6.
	var r = rng.randf()*100
	var total = 0
	
	var list = dict.keys()
	var i = 0
	var n = len(list)
	while i < n and total <= r:
		total += dict[list[i]]
		i+=1
	return list[i-1]

func new_base_operations(domain: Domain):
	#operations are common to both players, depends on char played
	#but generated randomly
	
	var operation_preference = domain.get_operation_preference()
	var difficulty_preference = domain.get_difficulty_preference()
	var n = domain.get_nb_new_operations()
	
	var op_list = []
	for i in range(n):
		var type = ponderate_random_choice_dict(operation_preference)
		var diff = ponderate_random_choice_dict(difficulty_preference)
		op_list.append([type,diff])
	return op_list
	
func _on_round_timer_timeout():
	game_state = 3
	bonus_menu_p1.visible = true
	$shop_timer.start(shopping_duration)
	emit_signal("game_pause")
	emit_signal("shopping_time")
	
	#start shop round
	bonus_menu_p1.visible = true
	
	#generate new bonuses and operations
	var new_operations_p1 = new_base_operations(domain1)
	var new_operations_p2 = new_base_operations(domain2)
	
	bonus_menu_p1.set_pattern(domain1.get_pattern())
	bonus_menu_p1.set_new_operations(new_operations_p1, new_operations_p2)
	
	bonus_menu_p1.set_erase_price(domain1.get_erase_price())
	bonus_menu_p1.set_swap_price(domain1.get_swap_price())
	
	var bonus_p1 = domain1.get_bonus_dict()
	var bonus_p2 = domain2.get_bonus_dict()
	
	bonus_menu_p2.set_pattern(domain2.get_pattern())
	bonus_menu_p2.set_new_operations(new_operations_p2, new_operations_p1)
	bonus_menu_p2.set_erase_price(domain2.get_erase_price())
	bonus_menu_p2.set_swap_price(domain2.get_swap_price())
	
	#make ai shopping
	var actions = shopping_possible_actions(domain2, bonus_menu_p2)
	var did_action = true
	while did_action and len(actions) > 0 and $shop_timer.time_left > 1:
		var inc_min_op_pow = domain2.get_least_powerful_op()
		var new_buyable_op = bonus_menu_p2.get_buyable_new_operations()
		var list_op_as_tuple = []
		for op in new_buyable_op:
			list_op_as_tuple.append(op.get_pattern_element())
		var shop_max_op_pow = global.most_powerful_op(list_op_as_tuple)
		
		var best_action = actions[0]
		var best_score = 0
		print("a??")
		for action in actions:
			
			var score = evaluation(action, domain2, bonus_menu_p2, inc_min_op_pow, shop_max_op_pow)
			if score > best_score:
				best_action = action
				best_score = score
		print("a?")
		ai_shop_play(best_action)
		actions = shopping_possible_actions(domain2, bonus_menu_p2)
		print(actions)
func ai_shop_play(action):
	var action_type = action[0]
	var op = action[1]
	var price = action[2]

	match action_type:
		"BUY":
			domain2.new_operation(op[0], op[1], price)
			print(str(action) + " DONE")
			return true
		"ERASE":
			domain2.erase_operation(op)
			print(str(action) + " DONE")
			return true
	return false
func evaluation(action, domain, bonus_menu, inc_min_op_pow, shop_max_op_pow):
	var action_type = action[0]
	#ayaaaaaaaaa (flemme)
	var op_or_index = action[1]
	var price = action[2]
	var score = 0
	var pattern = domain.get_pattern()
	
	match action:
		"BUY":
			score += global.get_op_potential_by_obj(op_or_index)
		"ERASE":
			if len(pattern) < 7:
				score = -10
			else:
				score += global.get_op_power_by_obj(shop_max_op_pow) - global.get_op_power_by_obj(pattern[op_or_index])
	return score
	
func shopping_possible_actions(domain, bonus_menu):
	var actions = []
	var money = domain.get_money()
	var new_buyable_op = bonus_menu.get_buyable_new_operations()
	
	if len(domain.get_pattern()) < 8:
		for op in new_buyable_op:
			var price = op.get_price()
			if price <= money:
				actions.append(["BUY", op.get_pattern_element(), price])
	
	if bonus_menu.get_erase_price() <= money:
		#loop variable needed
		var pattern = domain.get_pattern()
		for i in range(len(pattern)):
			actions.append(["ERASE", i, bonus_menu.get_erase_price()])
	
	return actions
	
func can_buy_anything(domain, bonus_menu):
	var can_i = true
	var money = domain.get_money()
	can_i = bonus_menu.get_swap_price() <= money and bonus_menu.get_erase_price()
	var new_op = bonus_menu.get_buyable_new_operations()
	var n = len(new_op)
	if !can_i and n > 0:
		var min_price = new_op[0].get_price()
		for i in range(n):
			var price = new_op[i].get_price()
			if min_price > price:
				min_price = price
		can_i = money >= min_price
		
	return can_i
	
func _on_pre_game_timer_timeout():
	bonus_menu_p1.visible = false
	game_state = 1
	$round_timer.start(round_duration)
	timer_p2.start(2)
	if timer_p2.get_time_left() == 0:
		timer_p2.start(2)
	emit_signal("game_resume")
	#start game
	
func _on_shop_timer_timeout():
	game_state = 0
	bonus_menu_p1.make_op_selectionnable(false, false)
	bonus_menu_p1.visible = false
	
	$pre_game_timer.start(pre_round_duration)
	emit_signal("new_round")
	#start pre_game


func _on_bonus_menu_player_ask_to_buy_operation(op):
	print("Signal transféré à la scène principale")
	
	var id = op.get_type()
	var diff = op.get_diff()
	var price = op.get_price()
	var result = domain1.buying_operation_attempt(price)
	print("Résultat du signal: " + str(result))
	var index: int
	
	op.set_display_type(Operation_Display.DISPLAY_TYPE.BASIC)
	#pop_ups
	match result:
		Domain.BUYING_OP_ATTEMPT_RESULT.FREE_SPACE:
			print("Espace libre")
			domain1.new_operation(id, diff, price, -1)
			op.set_display_type(Operation_Display.DISPLAY_TYPE.BOUGHT)
			#pop-up replace?
			pass
		Domain.BUYING_OP_ATTEMPT_RESULT.NO_SPACE:
			print("Pas d'espace libre")
			var pop_up = AcceptDialog.new()
			add_child(pop_up)
			pop_up.set_text("L'incantation ne peut pas être complexifiée davantage! Supprimez un des ses éléments avant.")
			pop_up.popup_centered()
			
			op.set_display_type(Operation_Display.DISPLAY_TYPE.BUYING)
#			
		Domain.BUYING_OP_ATTEMPT_RESULT.NO_MONEY:
			print("Pas assez d'argent")
			var pop_up = AcceptDialog.new()
			add_child(pop_up)
			pop_up.set_text("Vous n'avez pas assez d'argent!")
			pop_up.popup_centered()
			op.set_display_type(Operation_Display.DISPLAY_TYPE.BUYING)
		Domain.BUYING_OP_ATTEMPT_RESULT.ERROR:
			op.set_display_type(Operation_Display.DISPLAY_TYPE.BUYING)
			
	#to remove later
	op.set_display_type(Operation_Display.DISPLAY_TYPE.BUYING)
	
	bonus_menu_p1.set_display_potential(domain1.get_base_potential())
	bonus_menu_p1.set_pattern(domain1.get_pattern())



func _on_bonus_menu_player_wants_to_erase_operation():
	if domain1.can_erase_operation():
		#in order:
		#make shop operations unbuyable
		bonus_menu_p1.set_shop_operations_buyable(false)
		#activate cancel button and disable swap and erase buttons
		#make incantation operations selectable
		bonus_menu_p1.change_state(BonusMenu.STATE.SELECTING)
		#yield selected signal
		var erase_index = yield(bonus_menu_p1.select_operation(), "completed")
		var confirmed = true
		#confirm ? (only if enough time)
#		if $shop_timer.get_time_left() > 3.0 :
#			var pop_up = ConfirmationDialog.new()
#			add_child(pop_up)
#			pop_up.set_text("Confirmer l'opération?")
#			pop_up.popup_centered()
#			pop_up.get_ok().connect("pressed", self, "confirmed")
#			pop_up.get_cancel().connect("pressed", self, "cancelled")
#			confirmed = yield()
		#substract the cost from domain money
		#erase the operation from incantation
		domain1.erase_operation(erase_index)
		#update the incantation display
		bonus_menu_p1.set_pattern(domain1.get_pattern())
		#make shop operations buyable
		#disable cancel button and activate swap and erase buttons
		bonus_menu_p1.change_state(BonusMenu.STATE.IDLE)
	else:
		var pop_up = AcceptDialog.new()
		add_child(pop_up)
		pop_up.set_text("Vous n'avez pas assez d'argent!")
		pop_up.popup_centered()
		


func _on_bonus_menu_player_wants_to_swap_operations():
	if domain1.can_swap_operations():
		var pop_up = AcceptDialog.new()
		add_child(pop_up)
		pop_up.set_text("Non implémenté! Dsl!")
		pop_up.popup_centered()
	else:
		var pop_up = AcceptDialog.new()
		add_child(pop_up)
		pop_up.set_text("Vous n'avez pas assez d'argent!")
		pop_up.popup_centered()
