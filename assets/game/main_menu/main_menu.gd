extends Control

signal transition_requested(state: States.GameState)

@export var music: Resource

func _ready():
	AudioManager.play_music(music)

func _on_play_button_pressed():
	transition_requested.emit(States.GameState.GAME)
