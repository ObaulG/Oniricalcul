extends Node

func set_3textures_bar(node_dict, crescent_order, value, compare_value1, compare_value2):
	if node_dict["value_label"] != null:
		node_dict["value_label"].text = str(value)
		
	var bar = node_dict["bar"]
	bar.value = value
	
	if crescent_order:
		if bar.value < compare_value1:
			bar.texture_progress = global.bar_green
		elif bar.value < compare_value2:
			bar.texture_progress = global.bar_yellow
		elif bar.value >= compare_value2:
			bar.texture_progress = global.bar_red
	else:
		if bar.value < compare_value1:
			bar.texture_progress = global.bar_red
		elif bar.value < compare_value2:
			bar.texture_progress = global.bar_yellow
		elif bar.value >= compare_value2:
			bar.texture_progress = global.bar_green
	
	bar.rect_size = Vector2(100,14)
	
	
#{index de ItemList: clef de global.characters}
var association = {}
var itemList
var char_name
var char_descr
var icon_size = [128,128]

var charselected
var char_info


var op_gridcontainer

#base display element to duplicate for all operations
var op_p_display_base
var vbox_op_list
var op_display

var diff_range: HSlider
var diff_label: Label

onready var caracs_nodes = {
	"hp": {
		"name_label": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names/label_hp,
		"value_label": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names2/hp_value,
		"bar": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names3/hp_value,
	},
	"difficulty": {
		"name_label": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names/label_diff,
		"value_label": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names2/diff_value,
		"bar": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names3/bar_diff,
	},
	"impact_spell": {
		"name_label": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names/label_impact_spell,
		"value_label": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names2/spell_name,
		"bar": null,
	},
	"malus": {
		"name_label": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names/label_malus,
		"value_label": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names2/malus_value,
		"bar": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names3/malus_value,
	},
	"spell_power": {
		"name_label": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names/label_power,
		"value_label": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names2/power_value,
		"bar": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names3/power_value,
	},
	"threat_delay": {
		"name_label": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names/label_delay,
		"value_label": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names2/impact_delay,
		"bar": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names3/impact_delay,
	},
	"threat_hp": {
		"name_label": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names/label_toughness,
		"value_label": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names2/toughness_value,
		"bar": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names3/toughness_value,
	},
	"atk_speed": {
		"name_label": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names/label_speed,
		"value_label": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names2/casting_speed,
		"bar": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names3/casting_speed,
	},
	"spell_cost": {
		"name_label": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names/label_cost,
		"value_label": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names2/cost_value,
		"bar": $window/hbox1/settings/caracteristics/VBoxContainer/HBoxContainer/carac_names3/cost_value,
	},
}

func _ready():
	global.character = 0
	
	itemList = $window/hbox1/characters/charlist
	char_name = $window/hbox1/settings/char_name/hbox/name_label
	char_descr = $window/hbox1/settings/char_name/descr
	charselected = $window/hbox1/settings/char_name/hbox/name_label
	char_info = $window/hbox1/settings/informations/text_info

	charselected.text = global.text[1][global.lang]
	itemList.icon_mode = ItemList.ICON_MODE_TOP
	itemList.select_mode = ItemList.SELECT_SINGLE
	itemList.same_column_width = true
	
	var k = 0
	# adding char sprite in item list
	for charkey in global.char_data.keys():
		var character = global.char_data[charkey]
		var tex = global.get_resized_ImageTexture(character.get_icon_texture(), 128, 128)
		itemList.add_icon_item(tex)
		
		association[k] = charkey
		k = k+1
	
	op_gridcontainer = $window/hbox1/settings/informations/GridContainer
	vbox_op_list = $window/hbox1/settings/informations/GridContainer/list
	op_p_display_base = $window/hbox1/settings/informations/GridContainer/list/base
	# generate operation probability value display
	for op_index in global.OP_ID.keys():
		var op_node = op_p_display_base.duplicate()
		var bar = op_node.get_node("centering/probability_bar")
		var op_sprite = op_node.get_node("op")
		var atlas = AtlasTexture.new()
		atlas.set_atlas(global.sprite_sheet_operations)
		atlas.set_region(Rect2(64*(op_index-1), 0, 64, 64))

		op_sprite.texture = atlas
		op_node.set_name("operation"+str(op_index))
		vbox_op_list.add_child(op_node)
	op_display = $window/hbox1/settings/incantation/Incantation_Operations
	
	#we don't show void operation...
	op_p_display_base.visible = false
	
	diff_label = $window/hbox1/settings/diff/diff_label
	diff_range = $window/hbox1/settings/diff/HSlider
	
func _on_Button_button_down():
	if global.character != 0:
		global.diff = int(diff_range.value)
		get_tree().change_scene("res://scenes/main_field_game/maingame.tscn")
	else:
		print("Aucun personnage sélectionné !")
		#Pop-up ("no character selected!!!")
		
		
#Sur sélection d'une icône
func _on_ItemList_item_selected(index):
	var id = association[index]
	#Récupération de l'index correspondant
	print("Index ", index, " sélectionné: ", global.characters[association[index]]["name"])
	global.character = association[index]
	
	var character = global.char_data[id]
	var char_dico = global.characters[id]
	
	#Modifier le label du nom
	charselected.set_text(global.text[2][global.lang] + character.get_name())
	
	#Et afficher la description
	char_descr.set_text(character.get_descr())
	
	#Et les informations de jeu du perosnnage
	char_info.set_text(character.get_info())
	
	caracs_nodes["impact_spell"]["value_label"].set_text(Threat.THREAT_TYPE[character.get_threat_type()])
	
	#et modifier les barres de caractéristiques
	set_3textures_bar(caracs_nodes["difficulty"], true, character.get_estimated_diff(), 2, 4)
	set_3textures_bar(caracs_nodes["hp"], false, character.get_base_hp(), 18, 35)
	set_3textures_bar(caracs_nodes["malus"], true, character.get_malus_level(), 1, 3)

	op_display.update_operations(character.get_base_pattern())
	
	#puis modifier les probabilités d'apparition des opérations
	var probabilities = character.get_operation_preference()
	var i = 0
	for op_index in probabilities:
		var hbox_node = vbox_op_list.get_node("operation"+str(op_index))
		var hbox_value = probabilities[op_index]
		hbox_node.get_node("centering/probability_bar").value = hbox_value
		
		#tri par ordre décroissant (par insertion)
		var new_index = 0
		while new_index < i and vbox_op_list.get_child(new_index).get_node("centering/probability_bar").value > hbox_value :
			new_index += 1
		
		vbox_op_list.move_child(hbox_node, new_index)
		
		i += 1
	
	
func _on_perfection_contract_number_value_changed(value):
	$window/hbox1/settings/option5/Label3.text = "Réalisé si au moins " + str(value) + " opéations sont justes lors d'une manche."
	

func _on_speed_contract_number_value_changed(value):
	$window/hbox1/settings/option2/Label3.text = "Réalisé si une chaîne de " + str(value) + " opérations justes est réalisées lors d'une manche."

func _on_return_button_down():
	global.game_mode = 0
	
	get_tree().change_scene("res://scenes/titlescreen/title.tscn")


func _on_HSlider_value_changed(value):
	#value is float
	match(int(value)):
		0:
			diff_label.text = "Très facile"
		1:
			diff_label.text = "Facile"
		2: 
			diff_label.text = "Moyen"
		3:
			diff_label.text = "Difficile"
		4:
			diff_label.text = "Très difficile"
		5:
			diff_label.text = "Extrême"
		_:
			diff_label.text = "???"
