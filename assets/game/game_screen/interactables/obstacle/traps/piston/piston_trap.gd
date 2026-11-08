class_name PistonTrap
extends Trap

@export var reach := 44.0
@export var extend_time := 0.12
@export var hold_time := 0.3
@export var retract_time := 0.6

@export var head: AnimatableBody2D
# kill block of the head, should be a child of it
@export var hurtbox: Obstacle

var _head_rest: Vector2
var _stroke: Tween

func _ready() -> void:
	#crash if no head or hurtbox
	if head == null or hurtbox == null:
		print("No head or hurtbox")
		return
	_head_rest = head.position
	hurtbox.monitoring = false

func _fire() -> void:
	if head == null or hurtbox == null:
		print("No head or hurtbox")
		return
	if _stroke:
		_stroke.kill()
	head.position = _head_rest
	_stroke = create_tween()
	_stroke.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_stroke.tween_callback(hurtbox.set_deferred.bind(&"monitoring", true))
	_stroke.tween_property(head, "position", _head_rest + Vector2(0, reach), extend_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_stroke.tween_callback(hurtbox.set_deferred.bind(&"monitoring", false))
	_stroke.tween_interval(hold_time)
	_stroke.tween_property(head, "position", _head_rest, retract_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
