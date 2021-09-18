extends Node2D

class_name MagicProjectile

enum PROJECTILE_TYPE{
	STARS = 1, 
	LIGHTNING = 2,
}

signal impact_on_target()

var base_speed
var type
var power: int
var character: int
var id_player: int
var destination: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
