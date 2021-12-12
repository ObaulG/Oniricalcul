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
var domain
var base_data

onready var answer_timer = $answer_timer
onready var parent = get_parent()

func _ready():
	activated = false
	rng = parent.rng
	domain = parent.my_domain
	base_data = parent.my_domain.base_data
func activate_AI():
	activated = true

func determine_ai_time_to_answer():
	var op = base_data.pattern.get_current_op()
	var type = op.get_type()
	var diff = op.get_diff()
	var answer_time = AI_BASE_ANSWER_TIME_BY_DIFF[ai_diff] + AI_BASE_ANSWER_TIME_BY_OP_DIFF[diff-1]
	timer_p2.start(answer_time)
	bar_answering_p2.set_max(answer_time)
	bar_answering_p2.update_time(answer_time)
	
func _on_answer_timer_timeout():
	var will_answer_right = true
	if rng.randf() > 0.98:
		will_answer_right = false
	
	if will_answer_right:
		domain2.check_answer(result, answer_time_p2)
	else:
		domain2.check_answer("0", answer_time_p2)
		
	determine_ai_time_to_answer()
	
	if not domain2.is_incanting():
		var total_hp_threats = domain2.get_total_hp_threats()
		
		if total_hp_threats > domain2.get_defense_power():
			domain2.set_stance(Domain.INCANTATIONS.DEFENSE)
		else:
			domain2.set_stance(Domain.INCANTATIONS.ATTACK)


func _on_GameFieldMulti_game_state_changed(new_state):
	pass # Replace with function body.

