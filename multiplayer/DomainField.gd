extends Control


signal meteor_hp_changed(gid, id, hp)
signal meteor_impact(gid, threat_type, hp_current, power)
signal meteor_destroyed(gid, id)
signal magic_projectile_end_with_power_left(power, type)
signal first_threat_ref_changed(t)

onready var sending_meteor_area = $meteor_sender
onready var base_projectile_start = $base_projectile_start
onready var threats_container = $threats

var threat_count: int
var first_threat
var id_domain: int
var id_character: int
var rng
var gp_node

func _ready():
	#Link to GameFieldMulti node
	gp_node = get_parent().get_parent()
	rng = RandomNumberGenerator.new()
	threat_count = 0
	first_threat = null
	
func initialise(d_id, c_id):
	id_domain = d_id
	id_character = c_id

func determine_nearest_threat():
	var min_time = 999
	var time = null
	var count = 0
	for child in threats_container.get_children():
		if child is Threat:
			if not child.is_dead():
				count += 1
				time = child.get_remaining_time()
				if time < min_time:
					first_threat = child
					min_time = time
	threat_count = count
	
	if is_instance_valid(first_threat):
		print("Prochaine cible déterminée: " + str(first_threat.get_id()))
	else:
		print("Aucune cible trouvée...")
	emit_signal("first_threat_ref_changed")

func magic_projectile_incantation(power):
	var target = first_threat
	var start_pos = base_projectile_start.position
	
	create_magic_homing_projectile(target, id_character, start_pos, power)
	
func create_magic_homing_projectile(target, char_id, start_pos: Vector2, power):
	var new_projectile = global.projectile.instance()
	new_projectile.create(self, power, id_character, id_domain, target)
	threats_container.add_child(new_projectile)
	new_projectile.position = start_pos

func receive_threat(dico_threat, signals_connection = true):
	print("Météorite reçue")
	# Récupération des paramètres
	var hp = dico_threat["hp"]
	var id = dico_threat["meteor_id"]
	var sender_character = dico_threat["sender"]
	var type = dico_threat["type"]
	var power = dico_threat["power"]
	var delay = dico_threat["delay"]
	var side_effects = dico_threat["side_effects"]
	
	#La taille dépend de la puissance
	var scaling = power / 4.0
	
	var position = Vector2(rng.randi_range(20,330), -100)
	# vitesses en px/s
	var x_speed = 0
	var y_speed = 900 / delay 
	
	var meteor = global.threat.instance()
	meteor.set_name(str(id))
	threats_container.add_child(meteor)
	meteor.create(id, hp, type, power, delay, [self], x_speed, y_speed, signals_connection)
	meteor.position = position
	meteor.apply_scale(Vector2(scaling, scaling))
	meteor.set_texture(global.threat_texture)
	
	determine_nearest_threat()
	change_magic_projectiles_target()
	
func get_total_hp_threats():
	var total = 0
	for child in threats_container.get_children():
		if child is Threat:
			total += child.get_hp()
	return total
	
func remove_threat(meteor_id):
	var meteor_node = get_threat_by_id(meteor_id)
	#the meteor might have exploded already so we check if the node is still here
	if meteor_node:
		if not meteor_node.is_dead():
			meteor_node.remove_animation()
			
func change_magic_projectiles_target():
	if threat_presence():
		for child in threats_container.get_children():
			if child is MagicProjectile:
				child.change_target(first_threat)

func threat_presence():
	return threat_count > 0

func get_threat_by_id(id):
	return threats_container.get_node_or_null(str(id))
	
func get_nearest_threat():
	return first_threat
	
func get_collision_zone_to_enemy():
	return sending_meteor_area
	
#TO BE CONTINUED
func inflict_damage_to_threat(id_threat, n):
	var threat = get_threat_by_id(id_threat)
	if threat:
		threat.receive_damage(n)
	
func _on_threat_impact(id, threat_type, hp_current, power):
	print("meteor impact in domain " + str(id_domain))
	determine_nearest_threat()
	emit_signal("meteor_destroyed", id_domain, id)
	emit_signal("meteor_impact", id, threat_type, hp_current, power)
	
func _on_threat_destroyed(id, threat_type, power, id_character, over_damage, pos):
	determine_nearest_threat()
	emit_signal("meteor_destroyed", id_domain, id)
	
func _on_threat_hp_value_changed(id, hp):
	emit_signal("meteor_hp_changed",id_domain, id, hp)

# if the magic projectile gets to the warp zone, then the character can
# reuse it :
# - to send a meteor;
# - to empower the next incantation;
# - to heal himself;
# - etc.
func _on_meteor_sender_magic_projectile_inside(power, type):
	print("Magic power remaining: " + str(power))
	emit_signal("magic_projectile_end_with_power_left", id_domain, power, type)
