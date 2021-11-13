extends Control

signal bot_diff_changed(id, value)

const MIN_PLAYERS_DISPLAY: int = 4
onready var player_list = $scroller/vbox_characters

var players_count: int

func _ready():
	players_count = 0 

func add_player(name_player: String, id_player: int, id_character = -1, validated = false):
	var player_node
	if players_count > MIN_PLAYERS_DISPLAY:
		player_node = CharacterDisplay.new()
		add_child(player_node)
	else:
		player_node = player_list.get_child(players_count)
	
	player_node.connect("bot_diff_changed", self, "_on_bot_diff_changed")
	player_node.set_name(str(id_player))
	player_node.add_player(name_player, id_player)
	
	if id_character != -1:
		player_node.select_character(id_character)
	if validated:
		player_node.validate_choice()

	print("Player added to multiplechardisplay: " + name_player)
	players_count += 1
	
func remove_player_by_index(index: int):
	var player_node = player_list.get_child(players_count)
	if player_node:
		if players_count > MIN_PLAYERS_DISPLAY:
			player_node.queue_free()
		else:
			player_node.remove_player()
			# we must replace it
			remove_child(player_node)
			add_child(player_node)
		print("Player removed")
		players_count -= 1
	
func remove_player_by_id(id: int):
	for player in player_list.get_children():
		if player.get_player_id() == id and id > 0:
			player.remove_player()
			players_count -= 1
			print("Player removed")
			return

func remove_player_by_name(name: String):
	pass
	
func get_players_display_nodes():
	var players = []
	for p in player_list.get_children():
		if not p.is_bot():
			players.append(p)
	return players
	
func get_bot_display_nodes():
	var bots = []
	for b in player_list.get_children():
		if b.is_bot():
			bots.append(b)
	return bots
	
func get_player_by_id(id: int):
	for player in player_list.get_children():
		print(str(player.get_player_id()))
		if player.get_player_id() == id:
			return player
	return null

func get_bot_by_id(id: int):
	for bot in player_list.get_children():
		print(str(bot.get_player_id()))
		if bot.get_player_id() == id:
			return bot
	return null
	
func get_player_by_index(index):
	pass
	
func get_player_by_name(name):
	pass
	
func set_player_name_by_index(name: String, index: int):
	pass

func _on_bot_diff_changed(id, value):
	emit_signal("bot_diff_changed", id, value)
