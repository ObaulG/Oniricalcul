extends Control

signal bot_diff_changed_bis(id, value)
signal player_added(node)

const MIN_PLAYERS_DISPLAY: int = 4
onready var player_list = $scroller/vbox_characters

var players_count: int
var bot_count: int

func _ready():
	players_count = 0 
	bot_count = 0
	
func add_player(name_player: String, net_id: int, game_id: int, id_character = -1, validated = false, is_bot = false):
	print("Adding player to UI")
	var player_node = global.character_display.instance()
	
	#All players should be displayed before the bots.
	var insertion_index = players_count -1
	if is_bot:
		insertion_index += bot_count
		
	print("Inserting character display at index " + str(insertion_index))
	if insertion_index < 0:
		player_list.add_child(player_node)
	else:
		var last_node_before_insertion = player_list.get_child(insertion_index)
		
		player_list.add_child_below_node(last_node_before_insertion, player_node)
	
	player_node.cancel_validation()
	player_node.connect("bot_diff_changed", self, "_on_bot_diff_changed")
	player_node.set_name(str(net_id))
	player_node.add_player(name_player, net_id, game_id)
	
	if id_character != -1:
		player_node.select_character(id_character)
	if validated:
		player_node.validate_choice()

	if is_bot:
		player_node.set_bot(true)
		bot_count += 1
		print("Bot added to multiplechardisplay: " + name_player)
	else:
		players_count += 1
		print("Player added to multiplechardisplay: " + name_player)
	
	emit_signal("player_added", player_node)
	
func add_player_node(player_node, insertion_index):
	print("Inserting character display at index " + str(insertion_index))
	if insertion_index < 0:
		player_list.add_child(player_node)
	else:
		var last_node_before_insertion = player_list.get_child(insertion_index)
		player_list.add_child_below_node(last_node_before_insertion, player_node)
	
	
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
		if not player.is_bot() and player.get_id_player() == id and id > 0:
			player.remove_player()
			players_count -= 1
			player.queue_free()
			print("Player removed")
			return

func remove_bot_by_id(id: int):
	for bot in player_list.get_children():
		if bot.is_bot() and bot.get_id_player() == id and id > 0:
			bot.remove_player()
			bot_count -= 1
			bot.queue_free()
			print("Bot removed")
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
		print(str(player.get_id_player()))
		if player.get_id_player() == id:
			return player
	return null

func get_bot_by_id(id: int):
	for bot in player_list.get_children():
		print(str(bot.get_id_player()))
		if bot.get_id_player() == id:
			return bot
	return null

func get_bot_by_index(i: int):
	var bot_node = player_list.get_child(players_count - 1 + i)
	if bot_node:
		return bot_node
	return null

func get_player_by_index(index):
	pass
	
func get_player_by_name(name):
	pass
	
func set_player_name_by_index(name: String, index: int):
	pass

func _on_bot_diff_changed(id, value):
	emit_signal("bot_diff_changed_bis", id, value)
