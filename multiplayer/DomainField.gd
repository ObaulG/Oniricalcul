extends Control


onready var sending_meteor_area = $A2D_send_meteor
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
	
	threat_count = 0
	first_threat = null
	
func initialise(d_id, c_id, rng_m):
	id_domain = d_id
	id_character = c_id
	rng = rng_m
	
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

func create_magic_homing_projectile(target, char_id, start_pos: Vector2, power):
	var new_projectile = global.projectile.instance()
	new_projectile.create(self, power, get_parent().get_c, id_domain, target)
	threats_container.add_child(new_projectile)
	new_projectile.position = start_pos

func receive_threat(dico_threat, signals_connection = true):
	print("Météorite reçue")
	# Récupération des paramètres
	var hp = dico_threat["atk_hp"]
	var id = dico_threat["threat_id"]
	var sender_character = dico_threat["character"]
	var type = dico_threat["threat_type"]
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
	meteor.create(id, hp, type, power, delay, [gp_node,self], x_speed, y_speed, signals_connection)
	meteor.position = position
	meteor.apply_scale(Vector2(scaling, scaling))
	meteor.set_texture(global.threat_texture)
	
	change_magic_projectiles_target()
	
func remove_threat(meteor_id):
	var meteor_node = threats_container.get_node(str(meteor_id))
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

func inflict_damage_to_threat(id_threat, n):
	pass
	
func _on_threat_impact():
	determine_nearest_threat()
	
func _on_threat_destroyed():
	determine_nearest_threat()
