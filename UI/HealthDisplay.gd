extends Control

class_name HealthDisplay

enum DISPLAY_MODES {FULL, PERCENT, SHORT, NONE}

onready var healthbar = $vbox/HealthBar
onready var health_label = $vbox/labels/current_hp
onready var slash_label = $vbox/labels/slash
onready var max_label = $vbox/labels/max_hp
onready var tween = $Tween

var current_health

export(Gradient) var gradient
export(PackedScene) var health_point

var display_mode

func _ready():
	display_mode = DISPLAY_MODES.FULL
	healthbar.min_value = 0
	if get_parent() and get_parent().get("hp_max"):
		healthbar.max_value = get_parent().hp_max
	current_health = healthbar.max_value
	
func set_max(value):
	healthbar.max_value = value
	max_label.text = str(value)
	
func _process(_delta):
	healthbar.value = current_health
	var round_value = round(healthbar.value)
	health_label.text = str(round_value)

func update_healthbar(value):
	healthbar.texture_progress = global.bar_green
	if value < healthbar.max_value * 0.5:
		healthbar.texture_progress = global.bar_yellow
	if value < healthbar.max_value * 0.15:
		healthbar.texture_progress = global.bar_red
	healthbar.value = max(value, healthbar.max_value)

	tween.interpolate_property(self, "current_health", current_health, value, 0.6)
	if not tween.is_active():
		tween.start()
	show()

func update_labels():
	match(display_mode):
		DISPLAY_MODES.FULL:
			health_label.text = str(healthbar.value)
		DISPLAY_MODES.PERCENT:
			health_label = str(round(100*healthbar.value/healthbar.max_value))
		DISPLAY_MODES.SHORT:
			health_label.text = str(healthbar.value)

func set_display_mode(mode):
	display_mode = mode
	match(display_mode):
		DISPLAY_MODES.FULL:
			health_label.visible = true
			slash_label.visible = true
			max_label.visible = true
		DISPLAY_MODES.PERCENT:
			health_label.visible = true
			slash_label.visible = false
			max_label.visible = false
		DISPLAY_MODES.SHORT:
			health_label.visible = true
			slash_label.visible = false
			max_label.visible = false
		DISPLAY_MODES.NONE:
			health_label.visible = false
			slash_label.visible = false
			max_label.visible = false
		
