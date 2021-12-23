extends KinematicBody2D

class_name MagicProjectile

const BASE_SPEED = 500 #px/s

signal target_hit(damage)
signal target_destroyed()
signal target_changed()
signal target_not_found(power)
#signal body_entered(body)

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

func _ready():
	pass
	#connect("body_entered", self, "_on_MagicProjectile_body_entered")

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
	
func _process(delta):
	label_power.text = str(power)
	set_rotation(0)
	set_rotation(0)
	update_dest()
	update_velocity()
	look_at(destination)
	
	var collision = move_and_collide(delta*velocity)
	if collision:
		collision_handler(collision)
#the projectile behaves differently in client and in server :
# -server side: we apply the damages normally and the projectile
# remains if it's more powerful than the meteor, else it is destroyed;
# -client side: it moves and destroys itself with data inside, but 
# all damage application and meteor destruction will be done with rpcs.

func collision_handler(collision: KinematicCollision2D):
	#apply damages
	print("---------COLLISION---------")
	var collider_node = collision.collider
	print(collider_node)
	
	#we check first if it has reached the zone sending a meteor
	#to the enemy
	if collider_node.has_method("transfer_to_enemy"):
		print("Magic projectile converted into instant incantation!")
		if get_tree().is_network_server():
			var power_fraction = power * initial_power
			collider_node.transfer_to_enemy(power_fraction, type)
		queue_free()
	
	var meteor_current_hp = 9001
	
	if collider_node.has_method("hit"):
		meteor_current_hp = collider_node.get_hp()
		if get_tree().is_network_server():
			collider_node.hit(power, character, id_player, base_speed, type)
			emit_signal("target_hit", power)
		
	#as said, the client only process the movements of the projectile
	#and the effects are processed when the server calls rpc
	power -= meteor_current_hp
	if power <= 0:
		queue_free()
	call_deferred("change_target",caster.get_nearest_threat())
