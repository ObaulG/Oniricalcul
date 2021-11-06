extends Node2D

#The field game, with at least 2 players.
#Later, we might have a 3+ multiplayer mode,
#so we don't always update the screen.


# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect event handler to the player_list_changed signal
	network.connect("player_list_changed", self, "_on_player_list_changed")
	
	# Update the lblLocalPlayer label widget to display the local player name
	$HUD/PanelPlayerList/lblLocalPlayer.text = Gamestate.player_info["pseudo"]
	
	# Spawn the players
	if (get_tree().is_network_server()):
		spawn_players(Gamestate.player_info, 1)
	else:
		rpc_id(1, "spawn_players", Gamestate.player_info, -1)

func _on_player_list_changed():
	# First remove all children from the boxList widget
	for c in $HUD/PanelPlayerList/boxList.get_children():
		c.queue_free()
	
	# Now iterate through the player list creating a new entry into the boxList
	for p in network.players:
		if (p != Gamestate.player_info["net_id"]):
			var nlabel = Label.new()
			nlabel.text = network.players[p]["pseudo"]
			$HUD/PanelPlayerList/boxList.add_child(nlabel)

# Spawns a new player actor, using the provided player_info structure and the given spawn index
remote func spawn_players(pinfo, spawn_index):
	# If the spawn_index is -1 then we define it based on the size of the player list
	if (spawn_index == -1):
		spawn_index = network.players.size()
	
	if (get_tree().is_network_server() && pinfo["net_id"] != 1):
		# We are on the server and the requested spawn does not belong to the server
		# Iterate through the connected players
		var s_index = 1      # Will be used as spawn index
		for id in network.players:
			# Spawn currently iterated player within the new player's scene, skipping the new player for now
			if (id != pinfo["net_id"]):
				rpc_id(pinfo["net_id"], "spawn_players", network.players[id], s_index)
			
			# Spawn the new player within the currently iterated player as long it's not the server
			# Because the server's list already contains the new player, that one will also get itself!
			if (id != 1):
				rpc_id(id, "spawn_players", pinfo, spawn_index)
			
			s_index += 1
	
	# Load the scene and create an instance
	var pclass = load(pinfo["actor_path"])
	var nactor = pclass.instance()
	# domain initialization
	nactor.create(pinfo["id_character_playing"])
	
	# If this actor does not belong to the server, change the node name and network master accordingly
	if (pinfo["net_id"] != 1):
		nactor.set_network_master(pinfo["net_id"])
	nactor.set_name(str(pinfo["net_id"]))
	# Finally add the actor into the world
	add_child(nactor)


#note: meteor and projectile casts are only visual: if it is display
#on a basedomaindisplay, then it's not the main character so they should
#not send data from other players.

#attack from pid
remote func meteor_cast(pid: int, attack_data: Dictionary):
	pass
	#Determine the target

	#server code
#	if get_tree().is_network_server():
#		for id in network.players:
#			if id != id_domain:
#				pass

	
	#everyone code

remote func magic_projectile_cast(id_domain: int, target, char_id, start_pos: Vector2, power):
	if get_tree().is_network_server():
		pass
		
#calls result_answer
remote func check_answer(op, ans, id_domain):
	#only the server is habilitated to give the answer
	if get_tree().is_network_server():
		pass

#called on every client. 
remotesync func result_answer(id_domain, good_answer: bool):
	if get_tree().is_network_server():
		pass

remote func damage_taken(id_domain: int, n: int):
	if get_tree().is_network_server():
		pass

remote func threat_damage_taken(id_domain, id_meteor, n):
	pass
	
remote func damage_healed(id_domain: int, n: int):
	if get_tree().is_network_server():
		pass
		
remote func update_incantation(id_domain: int, n: int):
	if get_tree().is_network_server():
		pass
		
