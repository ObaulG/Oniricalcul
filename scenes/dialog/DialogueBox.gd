class_name DialogueBox
extends Control

onready var pause_calculator := get_node("PauseCalculator") as PauseCalculator
onready var tag_parser := get_node("CustomTagParser") as CustomTagParser
onready var content := get_node("Panel/dialogue") as RichTextLabel
onready var voice_player := get_node("DialogueVoicePlayer") as AudioStreamPlayer2D
onready var sound_player := get_node("SoundPlayer") as AudioStreamPlayer2D
onready var type_timer := get_node("TypeTyper") as Timer
onready var pause_timer := get_node("PauseTimer") as Timer

export(float) var volume
export(float) var pitch = 1
export(float) var reading_speed = 0.08
export(bool) var _playing_voice := false

signal message_completed()

func _ready():
	type_timer.set_wait_time(reading_speed)
	update_message("{p=1.0}Fra{s=3}cass{s=3} {p=1.0}NOW!")
	
func _process(_delta):
	pass
	#print("Temps restant avant reprise: " + str(pause_timer.get_time_left()))

# Swaps the current message with the one provided, and start the typing logic
func update_message(message: String) -> void:
	
	# Pause detection logic
	content.bbcode_text = tag_parser.extract_tags_from_string(message)
	content.visible_characters = 0
	
	type_timer.start()
	
	_playing_voice = true
	voice_player.play(0)

# Returns true if there are no pending characters to show
func message_is_fully_visible() -> bool:
	return content.visible_characters >= content.text.length() - 1

func is_typing_paused() -> bool:
	return pause_timer.get_time_left() > 0
	
# Called when the timer responsible for showing characters calls its timeout
func _on_TypeTyper_timeout() -> void:
	tag_parser.check_at_position(content.visible_characters)
	if content.visible_characters < content.text.length():
		content.visible_characters += 1
		print("caractère écrit")
		if not is_typing_paused():
			type_timer.start(reading_speed)
	else:
		_playing_voice = false
		type_timer.stop()
		emit_signal("message_completed")

# Called when the voice player finishes playing the voice clip
func _on_DialogueVoicePlayer_finished() -> void:
	if _playing_voice:
		voice_player.play(0)

# Called when the pause calculator node requests a pause
func _on_PauseCalculator_pause_requested(duration: float) -> void:
	
	_playing_voice = false
	type_timer.stop()
	pause_timer.wait_time = duration
	pause_timer.start(duration)

# Called when the pause timer finishes
func _on_PauseTimer_timeout() -> void:
	print("pause terminée")
	_playing_voice = true
	voice_player.play(0)
	type_timer.start(reading_speed)


func _on_CustomTagParser_pause_requested(duration):
	print("Début de la pause de " + str(duration))
	_playing_voice = false
	type_timer.stop()
	pause_timer.set_wait_time(duration)
	pause_timer.start(duration)


func _on_CustomTagParser_pitch_change_requested(value):
	pass # Replace with function body.


func _on_CustomTagParser_sound_requested(id):
	var sound_to_play = global.SOUND_ID[id]
	sound_player.stream = sound_to_play
	sound_player.play(0)


func _on_CustomTagParser_speed_change_requested(value):
	print("changement de vitesse: " + str(value))
	reading_speed = value
	type_timer.set_wait_time(reading_speed)


func _on_CustomTagParser_volume_change_requested(value):
	pass # Replace with function body.

