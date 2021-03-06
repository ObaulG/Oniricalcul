extends Control

class_name BaseDomainDisplay

const THREATLINE = preload("res://multiplayer/ThreatLineDisplay.tscn")
enum STAT{
	POINTS = 1,
	POTENTIAL,
	DEFENSE_POWER,
	CHAIN,
	SPEED,
	GOOD_ANSWERS
}

var player_id: int
var game_id: int
var parent_node

var waiting_for_transaction_end: bool

onready var base_data = $BaseDomainData
onready var spellbook = $BaseDomainData/Spellbook
onready var panel = $Panel
onready var hp_display = $Panel/hp_display
onready var texture_icon = $Panel/char_icon
onready var domain_field = $Panel/domain_field
onready var player_name_lbl = $Panel/player_name
onready var incantation_progress = $Panel/IncantationProgress
onready var stats_display = $Panel/stats_display
onready var threat_vbox_list = $Panel/threat_data_display/vbox
onready var incantation_display = $Panel/Incantation
onready var ai_node = $OniricAI
onready var stance_icon = $stance_icon

onready var nodes_stats_display = {
		points = $Panel/stats_display/points,
		potential = $Panel/stats_display/potential,
		defense_power = $Panel/stats_display/defense_power,
		chain = $Panel/stats_display/chain,
		speed = $Panel/stats_display/speed,
		good_answers = $Panel/stats_display/good_answers,
	}

func _ready():
	waiting_for_transaction_end = false
	parent_node = get_parent()
	player_id = -1
	domain_field.connect("meteor_destroyed", self, "_on_domain_field_meteor_destroyed")
	domain_field.connect("meteor_impact", self, "_on_domain_field_meteor_impact")
	domain_field.connect("meteor_hp_changed", self, "_on_domain_field_meteor_hp_changed")
	
func initialise(pinfo):
	player_id = pinfo["net_id"]
	game_id = pinfo["game_id"]
	var id_char = pinfo["id_character_selected"]
	base_data.initialise(id_char, game_id)
	hp_display.set_new_value(global.char_data[id_char].get_base_hp())
	hp_display.set_max_value(global.char_data[id_char].get_base_hp())
	var tex = global.char_data[id_char].get_icon_texture()
	texture_icon.texture = global.get_resized_ImageTexture(tex, 128, 128)
	
	player_name_lbl.text = pinfo["pseudo"]

	domain_field.initialise(game_id, base_data.id_character)
	
func activate_AI():
	ai_node.activate_AI()
	
func answer_action(good_answer, is_my_domain):
	print("Domain " + str(game_id) + ": answer received: " + str(good_answer))
	base_data.answer_response(good_answer, is_my_domain)
	
func shop_action(type, price, operations_selected_list):
	print("Player " + str(game_id) + ": application of shop operation")
	print(type)
	spellbook.spend_money(price)
	match(type):
		BonusMenuBis.BONUS_ACTION.BUY_OPERATION:
			base_data.spellbook.pattern.append(operations_selected_list[0])
		BonusMenuBis.BONUS_ACTION.ERASE_OPERATION:
			base_data.spellbook.pattern.remove(operations_selected_list[0])
		BonusMenuBis.BONUS_ACTION.SWAP_OPERATIONS:
			base_data.spellbook.pattern.swap_elements(operations_selected_list[0],
											operations_selected_list[1])
	update_stat_display(STAT.POTENTIAL, spellbook.pattern.get_power(0, true))
	update_stat_display(STAT.DEFENSE_POWER, spellbook.get_defense_power())

func update_all_stats_display():
	update_stat_display(STAT.POINTS, base_data.points)
	update_stat_display(STAT.POTENTIAL, base_data.spellbook.get_potential())
	update_stat_display(STAT.DEFENSE_POWER, base_data.spellbook.get_defense_power())
	update_stat_display(STAT.CHAIN, base_data.spellbook.chain)
	update_stat_display(STAT.SPEED, base_data.good_answers/max(1.0, base_data.game_time))
	update_stat_display(STAT.GOOD_ANSWERS, base_data.good_answers)
	
func update_hp_value(hp):
	print("updating hp values in nodes in domain "+str(game_id))
	base_data.set_hp_value(hp)
	hp_display.set_new_value(hp)
	
func update_stance(new_stance):
	base_data.spellbook.set_stance(new_stance)
	match(new_stance):
		1:
			stance_icon.texture = global.icons_textures.arrow
		2:
			stance_icon.texture = global.icons_textures.round_shield
		3:
			pass
			
#returns a dict containing values of all stats displayed
func get_array_stats_display():
	var dico = {
		points = base_data.points,
		potential = base_data.spellbook.get_power(0, true),
		defense_power = base_data.spellbook.get_defense_power(),
		chain = base_data.spellbook.chain,
		speed = base_data.good_answers/max(1.0, base_data.game_time),
		good_answers = base_data.good_answers
	}
	return dico
	
func get_parent_node():
	return parent_node
	
func get_money():
	return base_data.spellbook.get_money()
	
func add_threat(gid, threat_data, is_for_me = true):
	var threat_line_display = THREATLINE.instance()
	threat_line_display.name = str(threat_data["meteor_id"])
	threat_vbox_list.add_child(threat_line_display)
	threat_line_display.set_id(threat_data["meteor_id"])
	threat_line_display.update_hp(threat_data["hp"])
	threat_line_display.update_hp_max(threat_data["hp"])
	threat_line_display.update_power(threat_data["power"])
	threat_line_display.start(threat_data["delay"])
	print("ThreatLine added: " + threat_line_display.name)
	domain_field.receive_threat(threat_data)
	
func update_threat_hp(meteor_id, hp):
	var threat_display_node = threat_vbox_list.get_node_or_null(str(meteor_id))
	if threat_display_node:
		threat_display_node.update_hp(hp)

func threat_impact(threat_hp, power):
	print("threat impact confirmed in domain " + str(power))
	base_data.get_damage(power)
	
func remove_threat(id_threat):
	var threat_display_node = threat_vbox_list.get_node_or_null(str(id_threat))
	if threat_display_node:
		threat_display_node.queue_free()
		
	domain_field.remove_threat(id_threat)


func incantation_progress_changed(n):
	incantation_progress.update_nb_elements_completed(n)
	
func get_gid():
	return game_id
	
func update_transaction_status(is_waiting: bool):
	waiting_for_transaction_end = is_waiting

func is_waiting_for_transaction_end():
	return waiting_for_transaction_end

func is_eliminated():
	return base_data.eliminated
	
func is_bot():
	return ai_node.is_activated()
	
func update_stat_display(stat_name, x: float):
	var node_to_change
	
	match(stat_name):
		STAT.POINTS:
			node_to_change = nodes_stats_display.points
		STAT.POTENTIAL:
			node_to_change = nodes_stats_display.potential
		STAT.DEFENSE_POWER:
			node_to_change = nodes_stats_display.defense_power
		STAT.CHAIN:
			node_to_change = nodes_stats_display.chain
		STAT.SPEED:
			node_to_change = nodes_stats_display.speed
		STAT.GOOD_ANSWERS:
			node_to_change = nodes_stats_display.good_answers
		_:
			node_to_change = null

	if node_to_change:
		node_to_change.change_value_displayed(x)
	
#input handlers
func _on_check_answer_command():
	pass
	#we should not do anything here bc we are not supposed 
	#to send ourselves the data (this is a enemy display node)
	
func _on_changing_stance_command():
	pass
	
func _on_delete_digit():
	pass
	
func _on_write_digit():
	pass

func apply_elimination_ui():
	base_data.eliminated = true
	modulate = Color(0.21, 0.21, 0.21)
	if is_bot():
		ai_node.pause_AI()
#we display the field if the mouse comes in
func _on_BaseDomainDisplay_mouse_entered():
	print("mouse in basedomaindisplay")
	domain_field.show()

#and we hide it when it goes out
func _on_BaseDomainDisplay_mouse_exited():
	print("mouse exited basedomaindisplay")
	domain_field.hide()
		
func _on_BaseDomainData_eliminated(_gid):
	modulate = Color(0.21, 0.21, 0.21)

func _on_GameFieldMulti_changing_stance_command(new_stance):
	base_data.spellbook.set_stance(new_stance)

func _on_BaseDomainData_points_value_changed(n):
	update_stat_display(STAT.POINTS, n)

func _on_Spellbook_chain_value_changed(n):
	update_stat_display(STAT.CHAIN, n)

func _on_BaseDomainData_good_answers_value_changed(n):
	update_stat_display(STAT.GOOD_ANSWERS, n)

func _on_domain_field_meteor_destroyed(_game_id, meteor_id):
	if get_tree().is_network_server():
		remove_threat(meteor_id)

func _on_domain_field_meteor_impact(gid, threat_type, hp_current, power):
	if get_tree().is_network_server():
		print("damage application")
		base_data.get_damage(power)

func _on_domain_field_meteor_hp_changed(_game_id, meteor_id, hp):
	if get_tree().is_network_server():
		update_threat_hp(meteor_id, hp)
