extends Node2D

@onready var camera = $Camera2D

# Format: {label_node: minimum_zoom_level}
var labels = {}

func _ready():
	setup_labels()

func _process(delta):
	update_label_visibility()

func setup_labels():

	# Area labels (show at medium zoom)
	labels[$"Red Cross"] = 0.5
	
	# Main campus label (always visible)
	labels[$Ground/Entrance] = GlobalVariables.max_zoom

func update_label_visibility():
	var current_zoom = camera.zoom.x

	for label in labels.keys():
		var target_alpha = 1.0
		
		if current_zoom <= labels[label]:
			var scale_factor = clamp(labels[label] / current_zoom * 0.5, 0.8, 1.2)
			label.scale = Vector2(scale_factor, scale_factor)
		else:
				target_alpha = 0.0
			
		# Create tween for smooth transition
		var tween = create_tween()
		tween.tween_property(label, "modulate:a", target_alpha, 0.3)
