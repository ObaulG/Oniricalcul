extends Node

class_name Network

enum ERRORS{NO_ERROR=0,
			CONNECTION_ERROR=1,
			NAME_ALREADY_EXISTS=2,
			NAME_INCORRECT = 3,
			SERVER_FULL = 4}
			
enum INFO {
	NAME,
	CHARACTER,
	SOMETHING_ELSE
}

enum GAMESTATE {
	CHAR_SELECT = 1,
	GAME_LAUCHING,
	IN_GAME,
	GAME_END
}
#Contains all players data and handlers to keep
#data updated

signal server_created
signal join_success          # When the peer successfully joins a server
signal join_fail             # Failed to join a server
signal player_list_changed
signal player_added(id)
signal player_removed(pinfo) 
signal disconnected()
signal authorized_to_connect(approved, server_data)

signal bot_list_changed
signal bot_added(id)
signal bot_removed(id)


var server_info = {
	name = "Server",      # Holds the name of the server
	max_players = 2,      # Maximum allowed connections
	used_port = 0,        # Listening port
	game_state = GAMESTATE.CHAR_SELECT
}

var players = {}

var bots = {}

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	get_tree().connect("server_disconnected", self, "_on_disconnected_from_server")

	connect("join_success", self, "_on_join_success")
	
func create_server():
	# Initialize the networking system
	var net = NetworkedMultiplayerENet.new()
	
	# Try to create the server
	if (net.create_server(server_info.used_port, server_info.max_players) != OK):
		print("Failed to create server")
		return
	#Zlib compression, to use less bandwidth
	net.set_compression_mode(3)
	# Assign it into the tree
	get_tree().set_network_peer(net)
	# Tell the server has been created successfully
	emit_signal("server_created")
	register_player(Gamestate.player_info)
	
func join_server(ip, port):
	var net = NetworkedMultiplayerENet.new()
	if (net.create_client(ip, port) != OK) :
		print("Failed to create client")
		emit_signal("join_fail")
		end_connection()
	get_tree().set_network_peer(net)

remote func server_response_to_auth(approved: bool, server_data: Dictionary):
	emit_signal("authorized_to_connect", approved, server_data)
	
#sends data to server to check if it is correct
remote func _on_join_success():
	Gamestate.player_info["net_id"] = get_tree().get_network_unique_id()
	rpc_id(1,"authentication",Gamestate.player_info)
	
remote func authentication(pinfo: Dictionary):
	if get_tree().is_network_server():
		var sender = get_tree().get_rpc_sender_id()
		var pseudo = pinfo["pseudo"]
		print("Player " + str(sender) + " authentication...")
		var room_in_server = get_nb_players() < server_info.max_players
		var name_approved = verify_info(INFO.NAME, pseudo)
		
		var connection_approved = name_approved and room_in_server and server_info.game_state == GAMESTATE.CHAR_SELECT
		if connection_approved:
			#register the new player into the table
			print("Auth. approved! Registering the player on the table.")
			pinfo["game_id"] = create_game_id()
			register_player(pinfo)
		rpc_id(sender, "server_response_to_auth", connection_approved, server_info)

remote func register_player(pinfo):
	if (get_tree().is_network_server()):
		
		# We are on the server, so distribute the player list information throughout the connected players
		for id in players:
			# Send currently iterated player info to the new player
			rpc_id(pinfo["net_id"], "register_player", players[id])
			# Send new player info to currently iterated player, skipping the server (which will get the info shortly)
			if (id != 1):
				rpc_id(id, "register_player", pinfo)
				
		print("Sending bot data: ")
		print(bots)
		# and we also need to send bot data
		for id in bots:
			print("Bot " + str(id))
			# Send currently iterated player info to the new player
			rpc_id(pinfo["net_id"], "register_bot", bots[id])

	# Now to code that will be executed regardless of being on client or server
	print("Registering player ", pinfo["pseudo"], " (", pinfo["net_id"], ") to internal player table")
	players[pinfo["net_id"]] = pinfo          # Create the player entry in the dictionary
	print_net_players_table()
	emit_signal("player_added", pinfo["net_id"])
	#emit_signal("player_list_changed")     # And notify that the player list has been changed

remote func register_bot(pinfo):
	if get_total_players_entities() < server_info.max_players:
		pinfo["net_id"] = get_nb_bots() + 38
		pinfo["game_id"] = create_game_id()
		pinfo["pseudo"] = "Bot " + str(get_nb_bots()+1)
		if (get_tree().is_network_server()):
			# We are on the server, so distribute the player list information throughout the connected players
			for id in players:
				if (id != 1):
					rpc_id(id, "register_bot", pinfo)
					
		# Now to code that will be executed regardless of being on client or server
		print("Registering bot ", pinfo["pseudo"], " (", pinfo["net_id"], ") to internal bot table")
		bots[pinfo["net_id"]] = pinfo          # Create the player entry in the dictionary
		print_net_players_table()
		emit_signal("bot_added", pinfo["net_id"])
		#emit_signal("bot_list_changed")     # And notify that the player list has been changed
	else:
		print("No more room for a bot !")
		
func end_connection():
	print("Ending connection to server")
	get_tree().get_network_peer().close_connection()
	get_tree().set_network_peer(null)
	Gamestate.player_info["id_character_selected"] = -1
	Gamestate.player_info["character_validated"] = false
	players = {}
	
func print_net_players_table():
	print(str(Gamestate.player_info["net_id"]) + " - " + str(len(network.players)) + " players registered in :")
	for id in players:
		var nick = players[id]["pseudo"]
		print(nick + " - " + str(id))
		
	print(str(len(network.bots)) + " bots registered in :")
	for id in bots:
		var nick = bots[id]["pseudo"]
		print(nick + " - " + str(id))

#We need to ensure everyone has a unique game ID
func create_game_id():
	var id = 1
	var all_game_ids = get_all_game_ids()
	while id in all_game_ids:
		id += 1
	return id

# Peer trying to connect to server is notified on success
func _on_connected_to_server():
	print("Connection success ! Now asking to check name...")
	#the signals makes the client send his data (see join_success)
	emit_signal("join_success")

#Used by server to check 1 info from client
func verify_info(info_type: int, info) -> bool:
	var sender = get_tree().get_rpc_sender_id()
	var approved : bool = false
	if (get_tree().is_network_server()):
		match info_type:
			INFO.NAME: 
				approved = not pseudo_in_list(info)
			INFO.CHARACTER: pass
				#some other verification
			INFO.SOMETHING_ELSE: pass
	return approved
	
remote func unregister_player(id):
	print("Removing player ", str(id), " from internal table")
	
	print("table: " + str(players))
	if id in players:
		# Cache the player info because it's still necessary for some upkeeping
		var pinfo = network.players[id]
		# Remove the player from the list
		players.erase(id)
		# And notify the list has been changed
		#emit_signal("player_list_changed")
		print("table: " + str(players))
		# Emit the signal that is meant to be intercepted only by the server
		emit_signal("player_removed", pinfo)
	else:
		print("Player is already removed... ?")
	
remote func unregister_bot(id):
	print("Removing bot ", str(id), " from internal table")
	
	if id in bots:
		# Cache the player info because it's still necessary for some upkeeping
		var pinfo = network.bots[id]
		# Remove the player from the list
		network.bots.erase(id)
		# And notify the list has been changed
		#emit_signal("bot_list_changed")
		print("table: " + str(players))
		# Emit the signal that is meant to be intercepted only by the server
		emit_signal("bot_removed", pinfo)
	else:
		print("Player is already removed... ?")

remote func set_game_state(value):
	if get_tree().is_network_server():
		rpc("set_game_state", value)
	server_info.game_state = value
	

func pseudo_in_list(nick: String) -> bool:
	print("Checking nick " + nick)
	for id in players:
		print(nick + " =? "+players[id]["pseudo"])
		if nick == players[id]["pseudo"]:
			print("nick already in table!")
			return true
	return false
	
	
# Peer trying to connect to server is notified on failure
func _on_connection_failed():
	emit_signal("join_fail")
	end_connection()

	
# Everyone gets notified whenever a new client joins the server
func _on_player_connected(id):
	print("Client " + str(Gamestate.player_info["net_id"]) + ": player " + str(id) + " has connected !")

# Everyone gets notified whenever someone disconnects from the server
func _on_player_disconnected(id_player):
	#We remove the player from the network, with his data
	print("id player disconnected: " + str(id_player))
	
	if (get_tree().is_network_server()):
		# updata server player list
		for id in players:
			# we don't call the function on the player who has disconnected
			if (id != 1) and (id != id_player):
				rpc_id(id, "unregister_player", id_player)
	
	# Now to code that will be executed regardless of being on client or server
	print("Unregistering player ", id_player, ") to internal player table")
	unregister_player(id_player)

# Peer is notified when disconnected from server
func _on_disconnected_from_server():
	print("Disconnected from server")
	# Stop processing any node in the world, so the client remains responsive
	get_tree().paused = true
	# Clear the network object
	get_tree().set_network_peer(null)
	# Allow outside code to know about the disconnection
	emit_signal("disconnected")
	# Clear the internal player list
	players.clear()
	# Reset the player info network ID
	Gamestate.player_info["net_id"] = 1

func get_all_game_ids() -> Array:
	var game_id_array = []
	for player_data in network.players.values():
		game_id_array.append(player_data["game_id"])
		
	for player_data in network.bots.values():
		game_id_array.append(player_data["game_id"])
	
	return game_id_array
	
func get_nb_players():
	return len(players)

func get_nb_bots():
	return len(bots)
	
func get_total_players_entities():
	return get_nb_bots() + get_nb_players()
