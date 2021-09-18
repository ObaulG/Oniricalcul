extends Node


signal server_created
signal join_success                            # When the peer successfully joins a server
signal join_fail                               # Failed to join a server

var server_info = {
	name = "Server",      # Holds the name of the server
	max_players = 0,      # Maximum allowed connections
	used_port = 0         # Listening port
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func create_server():
	# Initialize the networking system
	var net = NetworkedMultiplayerENet.new()
	
	# Try to create the server
	if (net.create_server(server_info.used_port, server_info.max_players) != OK):
		print("Failed to create server")
		return
	
	# Assign it into the tree
	get_tree().set_network_peer(net)
	
	# Tell the server has been created successfully
	emit_signal("server_created")

func join_server(ip, port):
	var net = NetworkedMultiplayerENet.new()
	
	if (net.create_client(ip, port) != OK):
		print("Failed to create client")
		emit_signal("join_fail")
		return
		
	get_tree().set_network_peer(net)
	
# Peer trying to connect to server is notified on success
func _on_connected_to_server():
	emit_signal("join_success")


# Peer trying to connect to server is notified on failure
func _on_connection_failed():
	emit_signal("join_fail")
	get_tree().set_network_peer(null)
