#thx kehomsforge

extends Node

onready var scene_transition = $SceneTransitionRect

func _ready():
	network.connect("server_created", self, "_on_ready_to_play")
	network.connect("join_success", self, "_on_join_success")
	network.connect("join_fail", self, "_on_join_fail")
	network.connect("authorized_to_connect", self, "_on_authorized_to_connect")
	$PanelIP/txtLocalIp.text = str(IP.get_local_addresses())
	
func set_player_info():
	if (!$PanelPlayer/txtPlayerName.text.empty()):
		Gamestate.player_info["pseudo"] = $PanelPlayer/txtPlayerName.text

func _on_ready_to_play():
	scene_transition.change_scene("res://multiplayer/MultiplayerCharSelection.tscn")
	
func _on_join_success():
	print("Onirilobby: Connected to the server !")
	
func _on_btCreate_pressed():
	# Properly set the local player information
	set_player_info()
	
	# Gather values from the GUI and fill the network.server_info dictionary
	if (!$PanelHost/txtServerName.text.empty()):
		network.server_info.name = $PanelHost/txtServerName.text
	network.server_info.max_players = int($PanelHost/sbMaxPlayers.value)
	network.server_info.used_port = int($PanelHost/txtServerPort.text)
	
	# And create the server, using the function previously added into the code
	network.create_server()

func _on_btJoin_pressed():
	# Properly set the local player information
	set_player_info()
	var ip = $PanelJoin/txtServerIP.text
	var port = int($PanelJoin/txtServerPort.text)
	network.join_server(ip, port)
	
func _on_authorized_to_connect(approved: bool):
	if approved:
		scene_transition.change_scene("res://multiplayer/MultiplayerCharSelection.tscn")
	else:
		print("Connection denied!")

func _on_join_fail():
	print("Failed to join server")
	
func _on_btReturn_pressed():
	print("End of connection")
	network.end_connection()
	scene_transition.play()
	yield(scene_transition, "transition_finished")
	scene_transition.change_scene("res://scenes/titlescreen/title.tscn")
