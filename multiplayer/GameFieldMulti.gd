extends Node2D


signal domain_answer_response(id_domain, good_answer)
signal update_incantation(new_value)
#The field game, with at least 2 players.
#Later, we might have a 3+ multiplayer mode,
#so we don't always update the screen.
onready var my_domain = $main_player_domain
onready var enemy_domains = $enemy
onready var round_timer = $round_time_remaining

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
	for c in enemy_domains.get_children():
		c.queue_free()
	
	# Now iterate through the player list creating a new entry into the boxList
	for p in network.players:
		if (p != Gamestate.player_info["net_id"]):
			var nlabel = Label.new()
			nlabel.text = network.players[p]["pseudo"]
			enemy_domains.add_child(nlabel)

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
	enemy_domains.add_child(nactor)


#note: meteor and projectile casts are only visual: if it is display
#on a basedomaindisplay, then it's not the main character so they should
#not send data from other players.

#attack from pid to target_id
remote func meteor_cast(pid: int, target_id: int, threat_data: Dictionary):
	if get_tree().is_network_server():
		#data must be sent to everyone by the server
		for id in network.players:
			if id != 1:
				rpc_id(id, "meteor_cast", pid, target_id, threat_data)

	if target_id != my_domain.id_domain:
		var target_domain = enemy_domains.get_node(str(target_id))
		if target_domain:
			target_domain.domain_field.add_threat(pid, threat_data, false)
		else:
			pass
	else:
		my_domain.domain_field.add_threat(pid, threat_data)

remote func meteor_remove(pid: int, meteor_id: int):
	if get_tree().is_network_server():
		for id in network.players:
			if id != 1:
				rpc_id(id, "meteor_remove", pid, meteor_id)
			
	if pid == my_domain.id_domain:
		pass
	else:
		pass
	
remote func magic_projectile_cast(id_domain: int, target, char_id, start_pos: Vector2, power):
	if get_tree().is_network_server():
		#data must be sent to everyone by the server
		for id in network.players:
			if id != 1:
				rpc_id(id, "magic_projectile_cast", id_domain, target, char_id, start_pos, power)

	if id_domain != my_domain.id_domain:
		var target_domain = enemy_domains.get_node(str(id_domain))
		if target_domain:
			target_domain.domain_field.create_magic_homing_projectile(target, char_id, start_pos, power)
		else:
			pass
	else:
		my_domain.domain_field.create_magic_homing_projectile(target, char_id, start_pos, power)
		
#calls result_answer
remote func check_answer(op, ans, id_domain):
	#only the server is habilitated to give the answer
	if get_tree().is_network_server():
		var domain
		if id_domain != 1:
			domain = enemy_domains.get_node(str(id_domain))
		else:
			domain = my_domain
			
		if domain:
			var stat_calcul = [
				op.get_type(),
				op.get_diff(),
				op.get_parameters(),
				domain.base_data.get_answer_time(),
				ans, 
				true, #correct answer
			]
			# the result is stored inside the operation for now...
			
			#calling the function in other players instance
			if op.is_result(ans):
				for id in network.players:
					if id != 1:
						rpc("result_answer", id_domain, stat_calcul[5])
			else:
				stat_calcul[5] = false
				for id in network.players:
					if id != 1:
						rpc("result_answer", id_domain, stat_calcul[5])
			
			#then we call it on ourself
			result_answer(id_domain, stat_calcul[5])
	
#called from server by check_answer
remote func result_answer(id_domain, good_answer: bool):
	emit_signal("domain_answer_response", id_domain, good_answer)

remote func damage_taken(id_domain: int, n: int):
	if get_tree().is_network_server():
		for id in network.players:
			if id != 1:
				rpc_id(id, "damage_taken", id_domain, n)
			
	if id_domain == my_domain.id_domain:
		my_domain.base_data.get_damage(n)
	else:
		var domain = enemy_domains.get_node(str(id_domain))
		if domain:
			domain.base_data.get_damage(n)

remote func threat_damage_taken(id_domain, id_meteor, n):
	if get_tree().is_network_server():
		for id in network.players:
			if id != 1:
				rpc_id(id, "threat_damage_taken", id_domain, id_meteor, n)
			
	var domain_field
	var domain
	if id_domain == my_domain.id_domain:
		domain_field = my_domain.domain_field
	else:
		domain = enemy_domains.get_node(str(id_domain))
		if domain:
			domain_field = domain.domain_field
	
	if domain:
		domain_field.inflict_damage_to_threat(id_meteor, n)
		
remote func damage_healed(id_domain: int, n: int):
	if get_tree().is_network_server():
		for id in network.players:
			if id != 1:
				rpc_id(id, "damage_healed", id_domain, n)
	var domain_field
	var domain
	if id_domain == my_domain.id_domain:
		domain_field = my_domain.domain_field
	else:
		domain = enemy_domains.get_node(str(id_domain))
		if domain:
			domain_field = domain.domain_field
	if domain:
		domain_field.heal(n)

remote func update_incantation(id_domain: int, n: int):
	if get_tree().is_network_server():
		for id in network.players:
			if id != 1:
				rpc_id(id, "update_incantation", id_domain, n)
			
	var domain_field
	var domain
	if id_domain == my_domain.id_domain:
		domain_field = my_domain.domain_field
	else:
		domain = enemy_domains.get_node(str(id_domain))
		if domain:
			domain_field = domain.domain_field
	if domain:
		emit_signal("update_incantation", n)

func _on_threat_impact(meteor_id, threat_type, current_hp, power):
	#we only act if it is a node in our field
	if Gamestate.player_info["net_id"] != 1:
		rpc_id(1, "meteor_remove", my_domain.id_domain, meteor_id)
		rpc_id(1, "damage_taken", my_domain.id_domain, power)
	else:
		meteor_remove(my_domain.id_domain, meteor_id)

func _on_threat_destroyed(meteor_id, threat_type, power):
	if Gamestate.player_info["net_id"] != 1:
		rpc_id(1, "meteor_remove", my_domain.id_domain, meteor_id)
	else:
		meteor_remove(my_domain.id_domain, meteor_id)
