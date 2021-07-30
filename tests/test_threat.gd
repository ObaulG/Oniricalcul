extends Node2D

var threat_texture = load("res://meteor.jpg")
var threat = load("res://threat.tscn")

var domain
var player1


func _ready():

	player1 = Player.new()
	domain = $domain
	domain.create(1, player1, null, 1)
	
func one_damage():
	for t in get_tree().get_nodes_in_group("threats"):
		print(t)
		t.receive_damage(1)


func _on_Timer_timeout():
	one_damage()
