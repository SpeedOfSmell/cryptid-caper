class_name Dart
extends Obstacle

@export var speed := 220.0
@export var max_lifetime := 3.0 

var _velocity := Vector2.ZERO
var _life := 0.0

func launch(direction: Vector2) -> void:
	_velocity = direction * speed
	rotation = direction.angle()

func _ready() -> void:
	body_entered.connect(_on_solid_entered)

func _physics_process(delta: float) -> void:
	position += _velocity * delta
	_life += delta
	if _life >= max_lifetime:
		queue_free()

func _on_solid_entered(body: Node2D) -> void:
	if body is PlayerController:
		return
	queue_free()
