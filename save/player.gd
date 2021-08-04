extends Object

class_name Player

signal game_over()

var pseudo
var level
var experience

var inventory
var unlocked
var gametime
var timestamp_lastplayed

var continues
var game_finished

var time_played: float
func _init():
	var data = loadData()
	time_played = 0.0
	if data != null and data["success"]:
		pseudo = data["pseudo"]
		level = data["level"]
		experience = data["experience"]
		inventory = data["inventory"]
		unlocked = data["unlocked"]
		gametime = data["gametime"]
		timestamp_lastplayed = data["timestamp_lastplayed"]
		continues = data["continues"]
		game_finished = data["game_finished"]
	else:
		pseudo = "???"
		level = 1
		experience = 0
		inventory = []
		
		gametime = 0
		timestamp_lastplayed = null
		unlocked = {
			"characters": [],
			"bonus": [],
			"operations": [],
			"achievements": [],
		}
		continues = 3
		game_finished = false


func loadData():
	var file = File.new()
	var path = global.get_file_path("SAVE_FILE")
	file.open(path, file.READ)
	var textdata = file.get_as_text()
	file.close()
	var result_JSON = JSON.parse(textdata)
	var dico = result_JSON.get_result()
	if dico != null:
		if result_JSON.error != OK:
			print("[load_json_file] Error loading JSON file '" + path + "'.")
			print("\tError: ", result_JSON.error)
			print("\tError Line: ", result_JSON.error_line)
			print("\tError String: ", result_JSON.error_string)
			dico["success"] = false
		else:
			dico["success"] = true
	return dico
	
func save(time_played: float):
	var save_dict = {
		"pseudo": pseudo,
		"level": level,
		"experience": experience,
		"inventory": inventory,
		"unlocked": unlocked,
		"gametime": gametime + time_played,
		"continues": continues,
		"game_finished": game_finished,
		"timestamp_lastplayed": OS.get_unix_time()
	}
	var save_game = File.new()
	save_game.open(global.PATH["SAVE_FILE"], File.WRITE)
	save_game.store_line(to_json(save_dict))

func lose_continue():
	continues = max(0, continues-1)
	if continues == 0:
		emit_signal("game_over")

func _to_string():
	var s = pseudo + "\nlvl " + str(level) + "\ncontinues " + str(continues)
	s += str(unlocked)
	return s
