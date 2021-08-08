class_name DialogueVoicePlayer
extends AudioStreamPlayer2D
	
var _random_number_gen := RandomNumberGenerator.new()
	 
func _ready() -> void:
	_random_number_gen.randomize()
	
func play(from_position := 0.0) -> void:
	pitch_scale = _random_number_gen.randf_range(0.94, 1.06)
	.play(from_position)
