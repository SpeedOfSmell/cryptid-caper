class_name Character
extends CharacterBody2D

@export var speed : float = 200
@export var gravity : float = 1200

@export var sprite_node: AnimatedSprite2D
@export var standing_shape: CollisionShape2D
@export var ducking_shape: CollisionShape2D

func _process(_delta):
	# TODO: play walk, jump and duck animations once the art exists.
	if velocity.x > 0:
		sprite_node.play("idle_right")
	elif velocity.x < 0:
		sprite_node.play("idle_left")

func walk_input() -> float:
	return Input.get_axis("walk_left", "walk_right")
