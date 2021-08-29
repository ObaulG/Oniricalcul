extends Node

var sound_effects = {
	"accept" : load("res://sound/Accept.mp3"),
	"decline": load("res://sound/Decline.wav"),
	
}

var musics = {
	"titlescreen": load("res://music/impact-prelude-by-kevin-macleod-from-filmmusic-io.mp3")
}

onready var bgmusic_player := $bgmusic_player

func _ready():
	pass # Replace with function body.

func play_bg_music(name: String) -> void:
	if name in sound_effects.keys():
		bgmusic_player.stream = sound_effects[name]
		bgmusic_player.play()

