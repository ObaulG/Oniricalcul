extends Operation


var question_text: String

var answers: Array

func _init(q, a, ga, result, hardness, t, st = -1).(hardness, t, st):
	question_text = q
	answers = a
	result = ga
	self.result = result

func is_result(result_array: Array) -> bool:
	for r in result_array:
		if not r in result:
			return false
	return true

