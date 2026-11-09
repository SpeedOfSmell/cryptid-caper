class_name PlayerController
extends CharacterBody2D

@export var speed : float = 200
@export var gravity : float = 1200
# px/s per second that air speed above walk speed (from a dash) fades back down
@export var air_momentum_decay : float = 600

@export var sprite_node: AnimatedSprite2D
@export var standing_shape: CollisionShape2D
@export var ducking_shape: CollisionShape2D
var air_jumps_left := 0
var air_dashes_left := 0
var ground_dash_cooldown_left := 0.0
# 1 when facing right, -1 when facing left
var facing := 1.0

# the jump upgrade's value is the total number of jumps, including the one off the ground
func max_air_jumps() -> int:
	return maxi(int(UpgradeDatabase.get_value(Upgrade.UpgradeType.JUMP_LEVEL)) - 1, 0)

# the dash upgrade's value is the number of dashes the player can make before landing again
func max_air_dashes() -> int:
	return maxi(int(UpgradeDatabase.get_value(Upgrade.UpgradeType.DASH)), 0)

func _physics_process(delta):
	if velocity.x != 0:
		facing = signf(velocity.x)
	ground_dash_cooldown_left = maxf(ground_dash_cooldown_left - delta, 0.0)

func _process(_delta):
	sprite_node.flip_h = facing < 0

func walk_input() -> float:
	return Input.get_axis("walk_left", "walk_right")

# quick helper to find a one way floor to downjump
func is_on_one_way_floor() -> bool:
	var collision := move_and_collide(Vector2.DOWN, true)
	if collision == null:
		return false
	var layer := collision.get_collider() as TileMapLayer #only tile maps contain oneways
	if layer == null:
		return false
	var cell := layer.local_to_map(layer.to_local(collision.get_position() - collision.get_normal())) #position is the contact point, normal is the direction, subtract to get the point against surface facing
	#without the nudging of the normal would round into a different cell if the contact point is near a cell edge, and the normal is pointing away from the center of the cell
	var tile := layer.get_cell_tile_data(cell)
	return tile != null and tile.is_collision_polygon_one_way(0, 0)
