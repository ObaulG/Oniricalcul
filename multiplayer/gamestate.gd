extends Node

# Contains a player's data.

var player_info: Dictionary
var update_rate = 30  # How many game updates per second
var update_delta = 1.0 / update_rate

# Called when the node enters the scene tree for the first time.
func _init():
	player_info = global.player.get_multiplayer_dict().duplicate()
	reset()
	print("Informations joueurs terminées")
	
func reset():
	player_info["net_id"] = 1 # By default everyone receives "server ID"
	player_info["game_id"] = 1 #will be given in game
	player_info["actor_path"] = "res://multiplayer/PlayerDomain.tscn"  # The class used to represent the player in the game world
	player_info["is_bot"] = false
	player_info["bot_diff"] = -1
	player_info["id_character_selected"] = -1
	player_info["character_validated"] = false
	player_info["id_character_playing"] = -1
	
func get_data() -> Dictionary:
	return player_info

func set_update_rate(r):
	update_rate = r
	update_delta = 1.0 / update_rate

func get_update_delta():
	return update_delta

func no_set(r):
	pass
