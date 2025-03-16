extends CharacterBody2D

const move_speed: float = 1200

@export var taget_point: Node2D

@onready var nav_agent = $NavigationAgent2D

func _ready() -> void:
	nav_agent.target_position = taget_point.global_position
	

func _physics_process(delta: float) -> void:
	if not nav_agent.is_target_reached():
		var nav_dir = to_local(nav_agent.get_next_path_position()).normalized()
		velocity = nav_dir * move_speed * delta
		move_and_slide()


func _on_timer_timeout() -> void:
	if nav_agent.target_position != taget_point.global_position:
		nav_agent.target_position = taget_point.global_position
	
	#$PathFinderTimer.start()
