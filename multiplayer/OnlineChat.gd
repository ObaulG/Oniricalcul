extends Panel

const IP_COMMAND = "\\IP"
const PLAYERS_DATA_COMMAND = "\\players_data"
# Online chat. Does not include network connections.

onready var chat_display = $TextEdit
onready var chat_input = $LineEdit

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().connect("connected_to_server", self, "enter_room")
	get_tree().connect("network_peer_connected", self, "user_entered")
	get_tree().connect("network_peer_disconnected", self, "user_left")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func _input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_ENTER:
			send_message()
		if event.pressed and event.scancode == KEY_BACKSPACE:
			remove_last_character_message()
			
func user_entered(id):
	if id in network.players:
		var pinfo = network.players[id]
		write_message(pinfo["pseudo"] + " est connecté(e).")
	
func user_left(id):
	if id in network.players:
		var pinfo = network.players[id]
		write_message(pinfo["pseudo"] + " s'est déconnecté(e).")

func write_message(msg, end_line = true):
	if end_line:
		chat_display.text += "\n"
	chat_display.text += msg
	
func send_message():
	var msg = chat_input.text
	if msg == "":
		return
	chat_input.text = ""
	var id = Gamestate.player_info["net_id"]
	if msg == IP_COMMAND:
		pass
	if msg == PLAYERS_DATA_COMMAND:
		write_message(str(network.players))
	else:
		rpc("receive_message", id, msg)
	
func remove_last_character_message():
	var n = len(chat_input.text)
	if n > 0:
		chat_display.text = chat_display.text.substr(0, n-2)
	
sync func receive_message(id, msg):
	var nick = network.players[id]["pseudo"]
	write_message(nick + ": " + msg)
	
func enter_room():
	write_message("Connexion au serveur " + network.server_info["name"] + " réussie.")

func _server_disconnected():
	write_message("Déconnecté du serveur.")
