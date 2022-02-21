extends Control

class_name SingleAnswerNumber

var answer: String

onready var lb_answer: Label = $lb_answer

func _ready():
	lb_answer.text = ""
	clear_answer()

func write_digit(d):
	lb_answer.text += str(d)
	
func delete_digit():
	lb_answer.text = lb_answer.text.substr(0, len(lb_answer.text)-1)

func clear_answer():
	lb_answer.text = ""

func change_sign():
	if answer != "":
		if answer[0] == "-":
			answer = answer.substr(1, len(answer))
		else:
			answer = "-" + answer

func get_answer() -> String:
	return lb_answer.text
	


	

