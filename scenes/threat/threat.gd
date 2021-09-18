extends Node2D

const THREAT_TYPE = {
	1: "Type A",
	2: "Type B",
	3: "Type C",
}
signal impact(threat_type, current_hp, power)
signal destroyed(threat_type, power)
class_name Threat

var threat_type
var hp_current
var hp_max
var hp_bar

var x_speed
var y_speed

var power
var timer
var frozen_time_left
var position2d

var tween
var frozen
var isdead: bool

func create(hp, type, power, delay, player_node, x_speed, y_speed):
	print("Création du Threat")
	print("Temps: " + str(delay))

	isdead = false
	self.x_speed = x_speed
	self.y_speed = y_speed
	self.power = power
	frozen = false
	hp_current = hp
	hp_max = hp
	threat_type = type
	tween = $Tween
	hp_bar = $HealthDisplay
	hp_bar.set_max(hp_max)
	hp_bar.set_display_mode(HealthDisplay.DISPLAY_MODES.NONE)
	timer = Timer.new()
	timer.connect("timeout", self, "delay_elapsed")
	connect("impact", player_node, "_on_threat_impact")
	self.add_child(timer)
	
	timer.start(delay)
	print("Temps d'attente: ", str(timer.get_wait_time()))
	print("Temps restant: ", str(timer.get_time_left()))
	
func _process(dt):
	if not frozen:
		self.translate(Vector2(x_speed * dt, y_speed * dt))

func set_texture(texture):
	$Position2D/Sprite.texture = texture
	
func delay_elapsed():
	print("La météorite s'écrase...")
	emit_signal("impact",threat_type, hp_current, power)
	if not isdead:
		remove_animation()
	
func receive_damage(n):
	"""
	 Returns the amount of damage received above current_hp.
	"""
	var d = hp_current - n
	hp_bar.update_healthbar(hp_current)
	if d <= 0:
		hp_current = 0
		emit_signal("destroyed", threat_type, power)
		return -d
	else:
		hp_current = d
		return 0
	
func remove_animation(destroyed = true):
	timer.stop()
	$destroy_particles.emitting = true
	print("Météorite détruite")
	isdead = true
	tween.interpolate_property(self, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()
	print("Fin anim")
	yield(tween, "tween_all_completed")
	print("Retrait")
	queue_free()

func freeze():
	frozen = true
	timer.set_paused(true)
	
func unfreeze():
	frozen = false
	timer.set_paused(false)
	
func is_dead():
	return isdead
	
func get_hp():
	return hp_current
	
func get_power():
	return power
	
func get_remaining_time():
	return timer.time_left
	
func _to_string():
	return "Threat type " + str(threat_type) + " HP: " + str(hp_current) + "/"+str(hp_max)


func _on_Threat_impact(_threat_type, _current_hp, _power):
	x_speed = 0.0
	y_speed = 0.0
	if not isdead:
		remove_animation()


func _on_Tween_tween_all_completed():
	print("prout")


func _on_Area2D_area_entered(area):
	pass # Replace with function body.
