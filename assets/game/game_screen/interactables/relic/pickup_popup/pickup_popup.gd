class_name PickupPopup
extends Label

@export var rise := 6.0 
@export var fade_time := 0.25
@export var hold_time := 3.0

func _ready() -> void:
	var rest := position.y
	position.y += rise
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_time)
	tween.parallel().tween_property(self, "position:y", rest, fade_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(hold_time)
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	tween.parallel().tween_property(self, "position:y", rest - rise, fade_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
