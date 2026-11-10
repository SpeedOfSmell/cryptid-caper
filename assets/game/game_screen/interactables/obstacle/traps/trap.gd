class_name Trap
extends Node2D
# objects that player can't interact with, pushing out Obstacles.
# subclasses override _fire(), telegraph for indicator before it fires.

# current tree looks like
# trap -> obstacle spawner (consumed by dart spawning scene)
# trap -> obstacle spawner -> log trap (consumed by log spawning scene)
# trap -> piston spawner (consumed by piston spawner scene) as it's a special case of a trap

@export var interval := 2.0 #interval of firing
@export_range(0.0, 1.0) var phase := 0.0 #delay as a fraction of interval; a row at 0, 0.25, 0.5 fires in order
@export var telegraph_time := 0.3 #warning time
@export var fire_sfx: SfxEvent

var _elapsed := 0.0
var _telegraphed := false

#using notifications over _ready so children don't overwrite
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			_elapsed = -phase * interval
			set_physics_process(true)
		NOTIFICATION_PHYSICS_PROCESS:
			_advance(get_physics_process_delta_time())

func _advance(delta: float) -> void:
	_elapsed += delta
	if telegraph_time > 0.0 and not _telegraphed and _elapsed >= interval - telegraph_time:
		_telegraphed = true
		_telegraph()
	if _elapsed >= interval:
		_elapsed -= interval
		_telegraphed = false
		AudioManager.play_sfx_on(fire_sfx, self)
		_fire()

#overrideable
func _telegraph() -> void:
	pass

#overrideable
func _fire() -> void:
	pass
