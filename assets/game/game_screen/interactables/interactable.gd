class_name Interactable
extends Area2D
# Base for anything in a room the player can touch like hazards or pickup
# override _on_player_touched and apply their effect through PlayerManager.

signal triggered(player: PlayerController)

@export var one_shot := false 
@export var sfx: SfxEvent

# have a delay so that room coords dont cause weird glitch when entering new one for old coordinates
const ENTRY_SETTLE_PHYSICS_FRAMES := 2

var _used := false
var _armed_at_physics_frame := 0

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			body_entered.connect(_on_body_entered)
		NOTIFICATION_ENTER_TREE:
			_armed_at_physics_frame = Engine.get_physics_frames() + ENTRY_SETTLE_PHYSICS_FRAMES

func _on_body_entered(body: Node2D) -> void:
	var player := body as PlayerController
	if player == null or _used or Engine.get_physics_frames() < _armed_at_physics_frame:
		return
	_used = one_shot
	AudioManager.play_sfx(sfx)
	_on_player_touched(player)
	triggered.emit(player)
	if one_shot:
		queue_free()

#overrideable method
func _on_player_touched(_player: PlayerController) -> void:
	pass
