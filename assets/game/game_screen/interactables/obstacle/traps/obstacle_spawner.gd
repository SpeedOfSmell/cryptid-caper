class_name ObstacleSpawner
extends Trap

@export var obstacle_scene: PackedScene #the launched obstacle
@export var max_alive := 4

@export var spawn_point: Marker2D #where obstacles appear; its rotation (local +x) is the launch direction

var _alive: Array = []

func _fire() -> void:
	_alive = _alive.filter(func(node) -> bool: return is_instance_valid(node)) #convenient way to easily keep at max projectiles
	if _alive.size() >= max_alive:
		return
	var obstacle := obstacle_scene.instantiate() as Node2D
	add_sibling(obstacle)
	obstacle.global_position = spawn_point.global_position
	_launch(obstacle)
	_alive.append(obstacle)

#overrideable: set up the new obstacle. default sends it along the spawn point's facing
func _launch(obstacle: Node2D) -> void:
	if obstacle.has_method(&"launch"): #safeguard, ensure each has launch method
		obstacle.launch(spawn_point.global_transform.x.normalized()) #spawn point faces the launch direction
