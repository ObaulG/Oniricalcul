extends Control

#Only a simple stat display for the moment

onready var progression_display = $StatDisplay

func update_nb_max_elements(n):
	progression_display.set_max_value(n)
	
func update_nb_elements_completed(n):
	progression_display.set_new_value(n)

func _on_Spellbook_incantation_progress_changed(new_value):
	update_nb_elements_completed(new_value)

func _on_Spellbook_incantation_has_changed(L):
	update_nb_max_elements(len(L))
