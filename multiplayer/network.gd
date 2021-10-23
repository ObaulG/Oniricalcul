extends Node

class_name Network

enum ERRORS{NO_ERROR=0,
			CONNECTION_ERROR=1,
			NAME_ALREADY_EXISTS=2,
			NAME_INCORRECT = 3}
#Contains all players data and handlers to keep
#data updated

signal server_created
signal join_success          # When the peer successfully joins a server
signal join_fail             # Failed to join a server
signal player_list_changed
signal player_removed(pinfo) 

signal name_available(available)

var server_info = {
	name = "Server",      # Holds the name of the server
	max_players = 2,      # Maximum allowed connections
	used_port = 0         # Listening port
}

var players = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().connect("network_peer_connected", self, "_on_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	get_tree().connect("server_disconnected", self, "_on_disconnected_from_server")


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
	
func join_server(ip, port, pinfo):
	var net = NetworkedMultiplayerENet.new()
	
	if (net.create_client(ip, port) != OK) :
		print("Failed to create client")
		emit_signal("join_fail")
		end_connection()
		return ERRORS.CONNECTION_ERROR
		
	print("No connection error")
	
	get_tree().set_network_peer(net)
	print("My id: " + str(Gamestate.player_info["net_id"]))
	
	#waiting for the connection to be established
	yield(self, "join_success")
	
	#we can go to the char select room only if the nickname is not already taken
	#check on server list
	print("Server is  checking names...")
	
	rpc_id(1,"is_name_available", pinfo)
	
	var name_available = yield(self, "name_available")
	
	print("Name available: " + str(name_available))
	
	if not name_available:
		print("Name already exists!")
		emit_signal("join_fail")
		end_connection()
		return ERRORS.NAME_ALREADY_EXISTS
	
	return ERRORS.NO_ERROR
	
remote func register_player(pinfo):
	if (get_tree().is_network_server()):
		# We are on the server, so distribute the player list information throughout the connected players
		for id in players:
			# Send currently iterated player info to the new player
			rpc_id(pinfo["net_id"], "register_player", players[id])
			# Send new player info to currently iterated player, skipping the server (which will get the info shortly)
			if (id != 1):
				rpc_id(id, "register_player", pinfo)
				
	# Now to code that will be executed regardless of being on client or server
	print("Registering player ", pinfo["pseudo"], " (", pinfo["net_id"], ") to internal player table")
	players[pinfo["net_id"]] = pinfo          # Create the player entry in the dictionary
	print(players)
	emit_signal("player_list_changed")     # And notify that the player list has been changed

func end_connection():
	print("Ending connection to server")
	get_tree().get_network_peer().close_connection()
	get_tree().set_network_peer(null)
	players = {}
	
# Peer trying to connect to server is notified on success
func _on_connected_to_server():
	
	
	print("Connection success !")
	# Update the player_info dictionary with the obtained unique network ID
	Gamestate.player_info["net_id"] = get_tree().get_network_unique_id()
	
	# Request the server to register this new player across all connected players
	rpc_id(1, "register_player", Gamestate.player_info)
	
	# And register itself on the local list
	register_player(Gamestate.player_info)
	
	emit_signal("join_success")
	
remote func is_name_available(pinfo):
	var id = pinfo["net_id"]
	var pseudo = pinfo["pseudo"]
	print(pseudo + " ("+str(id) + ") wants to connect.")
	if (get_tree().is_network_server()):
		var available = not pseudo_in_list(pseudo)
		rpc_id(id, "answer_name_available", available)
		if not available:
			print("Name not available!")
			unregister_player(id)
			
remote func answer_name_available(available):
	emit_signal("name_available", available)
	
remote func unregister_player(id):
	print("Removing player ", str(id), " from internal table")
	
	print("table: " + str(players))
	if id in players:
		# Cache the player info because it's still necessary for some upkeeping
		var pinfo = network.players[id]
		# Remove the player from the list
		network.players.erase(id)
		# And notify the list has been changed
		emit_signal("player_list_changed")
		
		# Emit the signal that is meant to be intercepted only by the server
		emit_signal("player_removed", pinfo)
	else:
		print("Player is already removed... ?")
	
	
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
	pass
