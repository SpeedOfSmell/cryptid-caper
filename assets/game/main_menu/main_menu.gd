extends Control

signal transition_requested(state: States.GameState)


func _on_play_button_pressed():
	transition_requested.emit(States.GameState.GAME)
