extends Node

# Contains a player's data.

var player_info: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	player_info = global.player.get_multiplayer_dict().duplicate()
	player_info["net_id"] = 1 # By default everyone receives "server ID"
	player_info["actor_path"] = "res://scenes/domain/domain.tscn"  # The class used to represent the player in the game world
	
	#For character select
	player_info["id_character_selected"] = -1
	#Validated character id
	player_info["id_character_playing"] = -1
	
func get_data() -> Dictionary:
	return player_info

