extends Node2D

class_name MagicProjectile

const BASE_SPEED = 200 #px/s

signal target_hit(damage)
signal target_destroyed()
signal target_changed()
signal target_not_found(power)

enum PROJECTILE_TYPE{
	STARS = 1, 
	LIGHTNING = 2,
}

var caster
var base_speed
var type
var initial_power: int
var power: int
onready var label_power = $power
var character: int
var id_player: int
var destination: Vector2
var target: Node2D
onready var label_target = $target
var velocity: Vector2

var enemy_transfer_area2d
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func create(caster, power, character, id_player, target, base_speed = BASE_SPEED, type = PROJECTILE_TYPE.STARS):
	self.caster = caster
	enemy_transfer_area2d = caster.get_collision_zone_to_enemy()
	self.power = power
	self.initial_power = power
	self.character = character
	self.id_player = id_player
	self.target = target
	self.type = type
	self.base_speed = base_speed
	self.velocity = Vector2(0,0)
	
func change_target(new_target):
	print("Projectile: Tentative chgt cible")
	if is_instance_valid(new_target):
		print("Nvelle cible: ", str(new_target))
		target = new_target
	else:
		print("Projectile: Aucune cible trouvée. Envoi vers terrain ennemi")
		target = enemy_transfer_area2d
	emit_signal("target_changed")
	
func update_dest():
	if is_instance_valid(target):
		destination = target.get_position()
		label_target.text = str(target.get_id())
	else:
		label_target.text = "?"
		change_target(caster.get_nearest_threat())

func update_velocity():
	velocity = position.direction_to(destination) * base_speed 
	
func move(delta):
	self.translate(velocity * delta)
	
func _process(delta):
	label_power.text = str(power)
	set_rotation(0)
	set_rotation(0)
	update_dest()
	update_velocity()
	look_at(destination)
	move(delta)

func _on_Area2D_body_entered(body):
	#apply damages
	print("---------COLLISION---------------")
	print(body)
	
	#we check first if it has reached the zone sending a meteor
	#to the enemy
	if body.has_method("transfer_to_enemy"):
		var power_fraction = power * initial_power
		print("OMG")
		body.transfer_to_enemy(power_fraction, type)
		queue_free()
	
	var current_hp = 9001
	if body.has_method("hit"):
		current_hp = body.get_hp()
		body.hit(power, character, id_player, base_speed, type)
		emit_signal("target_hit", power)
	power -= current_hp
	if power <= 0:
		queue_free()
	call_deferred("change_target",caster.get_nearest_threat())