class_name PistonTrap
extends Trap

@export var reach := 44.0
@export var extend_time := 0.12
@export var hold_time := 0.3
@export var retract_time := 0.6

@export var head: AnimatableBody2D
# kill block of the head, should be a child of it
@export var hurtbox: Obstacle
@export var middle: NinePatchRect

var _head_rest: Vector2
var _stroke: Tween

func _ready() -> void:
	#crash if no head or hurtbox
	if head == null or hurtbox == null:
		print("No head or hurtbox")
		return
	_head_rest = head.position
	hurtbox.monitoring = false
	_set_extension(0.0)

func _fire() -> void:
	if head == null or hurtbox == null:
		print("No head or hurtbox")
		return
	if _stroke:
		_stroke.kill()
	_set_extension(0.0)
	_stroke = create_tween()
	_stroke.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_stroke.tween_callback(hurtbox.set_deferred.bind(&"monitoring", true))
	_stroke.tween_method(_set_extension, 0.0, reach, extend_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_stroke.tween_callback(hurtbox.set_deferred.bind(&"monitoring", false))
	_stroke.tween_interval(hold_time)
	_stroke.tween_method(_set_extension, reach, 0.0, retract_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _set_extension(extension: float) -> void:
	head.position = _head_rest + Vector2(0, extension)
	if middle:
		middle.offset_top = middle.offset_bottom - (roundf(extension) + 1.0)
