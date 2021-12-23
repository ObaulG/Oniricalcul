extends Node2D

const THREAT_TYPE = {
	1: "Type A",
	2: "Type B",
	3: "Type C",
}
signal impact(id, threat_type, hp_current, power)
signal hp_value_changed(id, new_hp)
signal destroyed(id, threat_type, power, id_character, over_damage, pos)

class_name Threat

var id: int
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

func create(id, hp, type, power, delay, player_nodes: Array, x_speed, y_speed, signals_connection = true):
	print("Création du Threat")
	print("Temps: " + str(delay))
	self.id = id
	name = str(id)
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
	
	if signals_connection:
		for player_node in player_nodes:
			connect("impact", player_node, "_on_threat_impact")
			connect("hp_value_changed", player_node, "_on_threat_hp_value_changed")
			connect("destroyed", player_node, "_on_threat_destroyed")
	self.add_child(timer)
	
	timer.start(delay)
	
func _process(dt):
	if not frozen:
		self.translate(Vector2(x_speed * dt, y_speed * dt))

func set_texture(texture):
	$Position2D/Sprite.texture = texture
	
func delay_elapsed():
	print("La météorite s'écrase...")
	emit_signal("impact",id, threat_type, hp_current, power)
	if not isdead:
		remove_animation()
	
func hit(power, character, id_character, base_speed, type):
	var over_damage = receive_damage(power)
	emit_signal("hp_value_changed", id, hp_current)
	if over_damage >= 0:
		# if done later, this threat will be counted alive
		isdead = true
		$CollisionShape2D.disabled = true
		emit_signal("destroyed", id, threat_type, power, id_character, over_damage, self.position)
		remove_animation(true)
		
func receive_damage(n):
	"""
	 Returns the amount of damage received above current_hp.
	"""
	var d = hp_current - n
	if d <= 0:
		hp_current = 0
		hp_bar.update_healthbar(hp_current)
		return -d
	else:
		hp_current = d
		hp_bar.update_healthbar(hp_current)
		return 0
	
func remove_animation(_destroyed_by_player = true):
	isdead = true
	$CollisionShape2D.disabled = true
	timer.stop()
	set_deferred("$CollisionShape2D.disabled", true)
	$destroy_particles.emitting = true
	tween.interpolate_property(self, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_all_completed")
	queue_free()

func freeze():
	frozen = true
	timer.set_paused(true)
	
func unfreeze():
	frozen = false
	timer.set_paused(false)
	
func get_id():
	return id
	
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

func _on_Threat_impact(_threat_id, _threat_type, _current_hp, _power):
	x_speed = 0.0
	y_speed = 0.0
	if not isdead:
		remove_animation()

func _on_Tween_tween_all_completed():
	print("prout")

