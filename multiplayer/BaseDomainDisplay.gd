extends Control

class_name BaseDomainDisplay


var player_id: int
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


func _ready():
	parent_node = get_parent()
	player_id = -1
	#connection on the input handler
	base_data.input_handler.connect("check_answer_command", self, "_on_check_answer_command")
	base_data.input_handler.connect("changing_stance_command", self, "_on_changing_stance_command")
	base_data.input_handler.connect("delete_digit", self, "_on_delete_digit")
	base_data.input_handler.connect("write_digit", self, "_on_write_digit")
	
	
func initialise(pid: int):
	player_id = pid
	var id_char = network.players[player_id]["id_character_selected"]
	base_data.initialise(player_id)
	
	var tex = global.char_data[id_char].get_icon_texture()
	texture_icon.texture = global.get_resized_ImageTexture(tex, 192, 192)
	
	player_name_lbl.text = network.players[id_char]["pseudo"]

func get_parent_node():
	return parent_node
	
func add_threat(id_threat, threat_data, is_for_me = true):
	pass
	
func remove_threat(id_threat):
	pass
	
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

