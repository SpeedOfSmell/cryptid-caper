extends Control

signal transition_requested(state: States.GameState)

@export var next_sound: SfxEvent

var page_number: int

# Called when the node enters the scene tree for the first time.
func _ready():
	page_number = 1
	%Screen1.visible = true
	%Screen2.visible = false

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.is_pressed()):
		AudioManager.play_sfx(next_sound)
		if page_number == 1:
			%Screen1.visible = false
			%Screen2.visible = true
			page_number += 1
		elif page_number == 2:
			transition_requested.emit(States.GameState.GAME)
		
