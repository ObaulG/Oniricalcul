extends Node

signal answer(good)
signal changing_stance(new_stance)

#bot hardness
const AI_BASE_ANSWER_TIME_BY_DIFF = [4.0, 3.2, 2.4, 1.6, 1.2, 0.6]

#operation hardnedss
const AI_BASE_ANSWER_TIME_BY_OP_DIFF = [0.05, 0.2, 1.2, 2.3, 4]

var hardness: int
var activated: bool
var rng: RandomNumberGenerator
var base_data

onready var answer_timer = $answer_timer
onready var domain = get_parent()
onready var server_game_field = get_parent().get_parent().get_parent()

func _ready():
	activated = false
	rng = RandomNumberGenerator.new()
	
func activate_AI():
	activated = true
	base_data = domain.base_data
	
func pause_AI():
	answer_timer.stop()
	
func determine_ai_time_to_answer():
	var op = base_data.spellbook.pattern.get_current_element()
	var answer_time = rng.randfn(AI_BASE_ANSWER_TIME_BY_DIFF[op[1]] + AI_BASE_ANSWER_TIME_BY_OP_DIFF[op[1]-1], 0.9)
	answer_timer.start(answer_time)
	
func is_activated():
	return activated
	
func set_hardness(value: int):
	hardness = value
	
func _on_answer_timer_timeout():
	var will_answer_right = true
	if rng.randf() > 0.98:
		will_answer_right = false
	
	server_game_field.result_answer(domain.get_gid(), will_answer_right)
	determine_ai_time_to_answer()
	
	#Determining if the bot should change his stance.
	var total_hp_threats = domain.domain_field.get_total_hp_threats()
	
	if total_hp_threats > base_data.spellbook.get_defense_power():
		server_game_field.changing_stance(domain.get_gid(), Domain.INCANTATIONS.DEFENSE)
	else:
		server_game_field.changing_stance(domain.get_gid(), Domain.INCANTATIONS.ATTACK)


func _on_GameFieldMulti_game_state_changed(new_state):
	pass # Replace with function body.

