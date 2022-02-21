extends Control

onready var num_input: TextEdit = $numerator_input
onready var den_input: TextEdit = $denominator_input
onready var frac: FractionDisplay = $FractionDisplay


func _ready():
	pass # Replace with function body.


func _on_numerator_input_text_changed():
	frac.update_numerator(int(num_input.text))

func _on_denominator_input_text_changed():
	frac.update_denominator(int(den_input.text))
