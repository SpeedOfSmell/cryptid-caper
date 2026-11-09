extends Control

signal transition_requested(state: States.GameState)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_restart_button_pressed():
	transition_requested.emit(States.GameState.GAME)


func _on_quit_button_pressed():
	transition_requested.emit(States.GameState.MAIN_MENU)
