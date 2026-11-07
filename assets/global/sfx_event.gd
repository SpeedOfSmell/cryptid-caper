class_name SfxEvent
extends Resource

@export var streams: Array[AudioStream] = []
@export_range(-24.0, 6.0) var volume_db := 0.0
@export_range(0.5, 2.0) var pitch_min := 1.0
@export_range(0.5, 2.0) var pitch_max := 1.0
