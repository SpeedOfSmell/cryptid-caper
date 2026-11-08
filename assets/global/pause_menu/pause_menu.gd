extends CanvasLayer

signal request_quit()

@onready var _score_label: Label = %ScoreValueLabel
@onready var _menu_panel: Panel = %MenuPanel
@onready var _confirmation_panel: Panel = %ConfirmationPanel

# Called when the node enters the scene tree for the first time.
func _ready():
	#PlayerManager.score_changed.connect(_update_score)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	# always allow closing; only gate opening on can_pause
	if visible:
		_close()
	else:
		_open()


func _open():
	#AudioManager.play_sfx(pause_open_sfx)
	_refresh()
	visible = true
	get_tree().paused = true


func _close():
	#AudioManager.play_sfx(pause_closed_sfx)
	visible = false
	#popup_window.hide()
	get_tree().paused = false
	
	
func _show_confirmation_screen():
	_menu_panel.visible = false
	_confirmation_panel.visible = true
	

func _close_confirmation_screen():
	_menu_panel.visible = true
	_confirmation_panel.visible = false


func _refresh():
	_score_label.text = str(PlayerManager.get_score())


func _update_score(score: int):
	_score_label.text = str(score)


func _on_resume_button_pressed():
	_close()


func _on_quit_button_pressed():
	_show_confirmation_screen()


func _on_confirm_button_pressed():
	request_quit.emit()


func _on_cancel_button_pressed():
	_close_confirmation_screen()
