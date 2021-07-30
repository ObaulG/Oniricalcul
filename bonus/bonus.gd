extends Container

const RARITY_COLORS = {
	1: Color("8a8a8a"),
	2: Color("3d93bc"),
	3: Color("147a37"),
	4: Color("aa1b1b"),
	5: Color("752a9a"),
	38: Color("e7ef57"),
}
var id
var id_node
var title
var title_node
var icon
var icon_node
var text
var text_node

func create(id: int):
	var bonus_dict = global.Bonus[id]
	id = bonus_dict["id"]
	
	title = bonus_dict["name"]
	title_node = $VBoxContainer/CenterContainer/title
	
	icon_node = $VBoxContainer/CenterContainer2/icon
	
	text = bonus_dict["effect"]
	text_node = $VBoxContainer/CenterContainer3/descr
	
	var rarity = bonus_dict["rarity"]
	
	if rarity > 1:
		$VBoxContainer/CenterContainer2/Particles2D.emitting = true
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
