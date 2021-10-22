#thx kehomsforge

extends Node

onready var scene_transition = $SceneTransitionRect

func _ready():
	network.connect("server_created", self, "_on_ready_to_play")
	network.connect("join_success", self, "_on_ready_to_play")
	network.connect("join_fail", self, "_on_join_fail")
	
	$PanelIP/txtLocalIp.text = str(IP.get_local_addresses())
	
func set_player_info():
	if (!$PanelPlayer/txtPlayerName.text.empty()):
		Gamestate.player_info["pseudo"] = $PanelPlayer/txtPlayerName.text

	
func _on_ready_to_play():
	get_tree().change_scene("res://multiplayer/MultiplayerCharSelection.tscn")
	

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
	
	var port = int($PanelJoin/txtServerPort.text)
	var ip = $PanelJoin/txtServerIP.text
	
	#if the connexion succeded, then we connect into character select
	if network.join_server(ip, port):
		scene_transition.play()
		yield(scene_transition, "transition_finished")
		get_tree().change_scene("res://multiplayer/MultiplayerCharSelection.tscn")
	print("Erreur de connexion...")
	
func _on_join_fail():
	print("Failed to join server")
	
func _on_btReturn_pressed():
	scene_transition.play()
	yield(scene_transition, "transition_finished")
	get_tree().change_scene("res://scenes/titlescreen/title.tscn")
