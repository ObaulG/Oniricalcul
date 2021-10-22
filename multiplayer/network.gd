extends Node

#Contains all players data and handlers to keep
#data updated

signal server_created
signal join_success          # When the peer successfully joins a server
signal join_fail             # Failed to join a server
signal player_list_changed
signal player_removed(pinfo) 

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
	register_player(Gamestate.player_info)
	print("Serveur créé")

	# Tell the server has been created successfully
	emit_signal("server_created")

func join_server(ip, port):
	var net = NetworkedMultiplayerENet.new()
	
	if (net.create_client(ip, port) != OK):
		print("Failed to create client")
		emit_signal("join_fail")
		return false
		
	get_tree().set_network_peer(net)
	return true
	
remote func register_player(pinfo):
	print("data player: " + str(pinfo))
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
	
# Peer trying to connect to server is notified on success
func _on_connected_to_server():
	emit_signal("join_success")
	# Update the player_info dictionary with the obtained unique network ID
	Gamestate.player_info["net_id"] = get_tree().get_network_unique_id()
	# Request the server to register this new player across all connected players
	rpc_id(1, "register_player", Gamestate.player_info)
	# And register itself on the local list
	register_player(Gamestate.player_info)

remote func unregister_player(id):
	print("Removing player ", network.players[id]["pseudo"], " from internal table")
	# Cache the player info because it's still necessary for some upkeeping
	var pinfo = network.players[id]
	# Remove the player from the list
	network.players.erase(id)
	# And notify the list has been changed
	emit_signal("player_list_changed")
	# Emit the signal that is meant to be intercepted only by the server
	emit_signal("player_removed", pinfo)
	
# Peer trying to connect to server is notified on failure
func _on_connection_failed():
	emit_signal("join_fail")
	get_tree().set_network_peer(null)

	
# Everyone gets notified whenever a new client joins the server
func _on_player_connected(id):
	pass


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
	emit_signal("player_list_changed")     # And notify that the player list has been changed

# Peer is notified when disconnected from server
func _on_disconnected_from_server():
	pass
