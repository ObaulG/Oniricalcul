extends Node

signal answer(good)
signal changing_stance(new_stance)

#bot hardness
const AI_BASE_ANSWER_TIME_BY_DIFF = [4.0, 3.2, 2.4, 1.6, 1.2, 0.6]

#operation hardnedss
const AI_BASE_ANSWER_TIME_BY_OP_DIFF = [0.05, 0.2, 1.2, 2.3, 4]

var hardness: int

func _ready():
	pass # Replace with function body.



func _on_answer_timer_timeout():
	var will_answer_right = true
	if rng.randf() > 0.98:
		will_answer_right = false
	
	if will_answer_right:
		domain2.check_answer(result, answer_time_p2)
	else:
		domain2.check_answer("0", answer_time_p2)
		
	answer_time_p2 = 0
	determine_ai_time_to_answer()
	
	if not domain2.is_incanting():
		var total_hp_threats = domain2.get_total_hp_threats()
		
		if total_hp_threats > domain2.get_defense_power():
			domain2.set_stance(Domain.INCANTATIONS.DEFENSE)
		else:
			domain2.set_stance(Domain.INCANTATIONS.ATTACK)
