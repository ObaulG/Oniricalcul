extends Node

enum STATES{
	INTRO_DIALOGUE, 
	PLAYING, 
	WINNING_DIALOGUE, 
	LOSING_DIALOGUE,
	GOOD_ENDING,
	BAD_ENDING,
	GAME_END,
}
signal game_over()
signal play_dialogue()

const MAX_CONTINUES = 2
const DIALOGUES = [
	{
		"intro": ["encounter_0", "encounter_0", "encounter_0",],
		
		"winning": ["winning_0", "winning_0", "winning_0"],
		
		"losing": ["losing_0", "losing_0", "losing_0"]
	},
	{
		"intro": ["encounter_1", "encounter_1", "encounter_1",],
		
		"winning": ["winning_1", "winning_1", "winning_1"],
		
		"losing": ["losing_1", "losing_1", "losing_1"]
	},
	{
		"intro": ["encounter_2", "encounter_2", "encounter_2",],
		
		"winning": ["winning_2", "winning_2", "winning_2"],
		
		"losing": ["losing_2", "losing_2", "losing_2"]
	},
	{
		"intro": ["encounter_f", "encounter_f", "encounter_f",],
		
		"winning": ["winning_f", "winning_f", "winning_f"],
		
		"losing": ["losing_f", "losing_f", "losing_f"]
	},
]

const GAMES_SETTINGS = [
	{
		"character_id": 1,
		"cpu_character_id": 4,
		"hardness": 1
	},
	{
		"character_id": 1,
		"cpu_character_id": 3,
		"hardness": 2
	},
	{
		"character_id": 1,
		"cpu_character_id": 2,
		"hardness": 3
	},
	{
		"character_id": 1,
		"cpu_character_id": 5,
		"hardness": 4
	}
	
]
const GOOD_ENDING_DIALOGUES = ["good_ending_1", "good_ending_2", "good_ending_3"]
const BAD_ENDING_DIALOGUE = "bad_ending"

var continues_used = 0
var current_state = STATES.INTRO_DIALOGUE
var progression = 0
var dying_points = [0,0,0]


			
func get_next_dialogue_to_be_played():
	if current_state in [0,2,3]:
		print(DIALOGUES[progression][get_type_name_of_dialogue()][continues_used])
		return DIALOGUES[progression][get_type_name_of_dialogue()][continues_used]
	elif current_state == STATES.GOOD_ENDING:
		return GOOD_ENDING_DIALOGUES[continues_used]
	elif current_state == STATES.BAD_ENDING:
		return BAD_ENDING_DIALOGUE[continues_used]
	else:
		return null
func get_current_game_settings():
	return GAMES_SETTINGS[progression]
func next_step(b = false):
	if current_state == STATES.INTRO_DIALOGUE:
		current_state = STATES.PLAYING
	elif current_state == STATES.PLAYING:
		if b:
			current_state = STATES.WINNING_DIALOGUE
		else:
			current_state = STATES.LOSING_DIALOGUE
	elif current_state == STATES.WINNING_DIALOGUE:
		winning_game()
	elif current_state == STATES.LOSING_DIALOGUE:
		losing_game()
	else:
		current_state = STATES.GAME_END

func get_state():
	return current_state
func set_state(value):
	current_state = value


func continue_used():
	continues_used += 1
	if continues_used > MAX_CONTINUES:
		emit_signal("game_over")
		current_state = STATES.BAD_ENDING
		
func winning_game():
	progression += 1
	current_state = STATES.INTRO_DIALOGUE
	if progression >= len(DIALOGUES):
		emit_signal("game_completed")
		current_state = STATES.GOOD_ENDING
		
func losing_game():
	dying_points[continues_used] = progression
	progression = 0
	current_state = STATES.INTRO_DIALOGUE
	continue_used()
	
func reset_game():
	continues_used = 0
	progression = 0
	dying_points = [0,0,0]



func get_type_name_of_dialogue():
	match current_state:
		STATES.INTRO_DIALOGUE:
			return "intro"
		STATES.WINNING_DIALOGUE:
			return "winning"
		STATES.INTRO_DIALOGUE:
			return "losing"
		_:
			return ""
