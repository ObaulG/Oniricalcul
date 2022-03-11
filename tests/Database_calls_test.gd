extends Control

const DB_PATH = "http://127.0.0.1:8000/"

#to be duplicated
onready var player_data_node_model = $player_data

onready var player_list = $scroller/player_list
onready var add_bt = $HBoxContainer/add_player_bt
onready var remove_bt = $HBoxContainer/remove_player_bt
onready var send_bt = $HBoxContainer/send_bt

onready var http_request_node = $HTTPRequest
# Called when the node enters the scene tree for the first time.
func _ready():
	http_request_node.connect("request_completed", self, "_on_request_completed")


func _on_add_player_bt_button_down():
	var n = player_list.get_child_count()
	if n < 16:
		var new_player = player_data_node_model.duplicate()
		player_list.add_child(new_player)


func _on_remove_player_bt_button_down():
	var n = player_list.get_child_count()
	if n > 2:
		player_list.get_child(n-1).queue_free()


func _on_db_call_button_down(command: int):
	match command:
		1:
			#building the gamedata dict
			var gamedata = {
				"timestamp_start": 0,
				"timestamp_end": 0,
				"players_dict": {}, #{game_id : pseudo}
				"game_actions": [],
				"eliminations": []
			}
			
			for child in player_list.get_children():
				var pseudo = child.get_node("pseudo")
				var gid = child.get_node("gid")
				var elimination_index = child.get_node("elimination_index")
				gamedata["players_dict"][gid] = pseudo
				gamedata["eliminations"].append(gid)
				
			var url = DB_PATH + "post/game_data"
				# Convert data to json string:
			var query = JSON.print(gamedata)
			# Add 'Content-Type' header:
			var headers = ["Content-Type: application/json"]
			http_request_node.request(url, 
									  headers,
									  true,
									  HTTPClient.METHOD_POST,
									  query)
		2:
			var pseudo = $ScrollContainer/VBoxContainer/database_action2/HBoxContainer/pseudo.text
			var url = DB_PATH + "player_data/by_pseudo/"+pseudo
			print(pseudo)
			var headers = []
			http_request_node.request(url, 
									  headers,
									  true,
									  HTTPClient.METHOD_GET)
		3:
			var pseudo = $ScrollContainer/VBoxContainer/database_action3/HBoxContainer/pseudo.text
			var url = DB_PATH + "new_player"
			var query = JSON.print({"pseudo": pseudo})
				# Convert data to json string:
			# Add 'Content-Type' header:
			var headers = ["Content-Type: application/json"]
			http_request_node.request(url, 
									  headers,
									  true,
									  HTTPClient.METHOD_POST,
									  query)
		_:
			pass

  
func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	print(json.result)
