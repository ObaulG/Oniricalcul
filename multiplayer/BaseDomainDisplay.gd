extends Control

class_name BaseDomainDisplay


var player_id: int
var game_id: int
var parent_node

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

func _ready():
	parent_node = get_parent()
	player_id = -1
	
	
	
func initialise(pid: int):
	player_id = pid
	game_id = network.players[player_id]["game_id"]
	var id_char = network.players[player_id]["id_character_selected"]
	base_data.initialise(id_char, pid)
	
	var tex = global.char_data[id_char].get_icon_texture()
	texture_icon.texture = global.get_resized_ImageTexture(tex, 192, 192)
	
	player_name_lbl.text = network.players[id_char]["pseudo"]

func activate_AI():
	ai_node.activate_AI()
	
func get_parent_node():
	return parent_node
	
func add_threat(id_threat, threat_data, is_for_me = true):
	pass
	
func remove_threat(id_threat):
	pass
	

func shop_action(type, price, element):
	spellbook.spend_money(price)
	match(type):
		BonusMenuBis.BONUS_ACTION.BUY_OPERATION:
			add_operation_to_pattern(element)
		BonusMenuBis.BONUS_ACTION.ERASE_OPERATION:
			spellbook.pattern.remove_by_element(element)
		BonusMenuBis.BONUS_ACTION.SWAP_OPERATIONS:
			pass
			
func add_operation_to_pattern(op):
	if op is Operation:
		spellbook.pattern.append(op)
		
func get_gid():
	return game_id
	
func is_eliminated():
	return base_data.eliminated
	

#we display the field if the mouse comes in
func _on_BaseDomainDisplay_mouse_entered():
	pass # Replace with function body.

#and we hide it when it goes out
func _on_BaseDomainDisplay_mouse_exited():
	pass # Replace with function body.

func _on_GameFieldMulti_domain_answer_response(id, good_answer):
	if id == base_data.id_domain:
		if good_answer:
			spellbook.good_answer()
		else:
			spellbook.wrong_answer()


func _on_BaseDomainData_eliminated():
	pass # Replace with function body.
