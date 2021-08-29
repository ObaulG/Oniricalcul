extends Node

#class_name SoundPlayer

var sound_effects = {
	"accept" : load("res://sound/Accept.mp3"),
	"decline": load("res://sound/Decline.wav"),
	
}

var musics = {
	"titlescreen": load("res://music/impact-prelude-by-kevin-macleod-from-filmmusic-io.mp3")
}

onready var bgmusic_player := $bgmusic_player
var bgmusic_playing: bool
func _ready():
	bgmusic_playing = false

func play_bg_music(name: String) -> void:
	if name in musics.keys():
		print("OMG the CD")
		var new_music_stream = musics[name]
		if new_music_stream != bgmusic_player.stream:
			bgmusic_player.stream = musics[name]
			bgmusic_player.play()
			bgmusic_playing = true



func _on_bgmusic_player_finished():
	bgmusic_playing = false
