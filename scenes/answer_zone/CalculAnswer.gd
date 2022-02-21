extends Control

class_name CalculAnswer

onready var answer = $SingleNumberAnswer

func _ready():
	clear_answer()

func write_digit(d):
	answer.write_digit(d)
	
func delete_digit():
	answer.delete_digit()

func clear_answer():
	answer.clear_answer()

func change_sign():
	answer.change_sign()

func get_answer() -> String:
	return answer.get_answer()
