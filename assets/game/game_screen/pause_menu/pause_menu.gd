extends CanvasLayer

@export var unfocusedLabel: LabelSettings
@export var focusedLabel: LabelSettings

signal request_quit()

@onready var _score_label: Label = %ScoreValueLabel
@onready var _menu_panel: PanelContainer = %MenuPanel
@onready var _confirmation_panel: PanelContainer = %ConfirmationPanel

var _fade_tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready():
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
	_fade_to(0.5, 0.4, %PauseFade)
	%ResumeButton.grab_focus()
	_refresh()
	visible = true
	get_tree().paused = true


func _close():
	#AudioManager.play_sfx(pause_closed_sfx)
	_fade_to(0, 0.1, %PauseFade)
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
	%ConfirmButton.grab_focus()


func _on_confirm_button_pressed():
	_close()
	request_quit.emit()


func _on_cancel_button_pressed():
	_close_confirmation_screen()
	%ResumeButton.grab_focus()

func _fade_to(target: float, duration: float, effect: ColorRect) -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)  # keeps running while paused
	_fade_tween.tween_property(effect.material, "shader_parameter/progress", target, duration)
	await _fade_tween.finished

func _switch_button_label_settings(button: TextureButton, settings: LabelSettings):
	var label: Label = button.find_children("*", "Label", true, false)[0]
	label.label_settings = settings

func _on_resume_button_focus_entered():
	_switch_button_label_settings(%ResumeButton, focusedLabel)
	
func _on_resume_button_focus_exited():
	if not %ResumeButton.is_hovered():
		_switch_button_label_settings(%ResumeButton, unfocusedLabel)

func _on_resume_button_mouse_entered():
	_switch_button_label_settings(%ResumeButton, focusedLabel)

func _on_resume_button_mouse_exited():
	if not %ResumeButton.has_focus():
		_switch_button_label_settings(%ResumeButton, unfocusedLabel)


func _on_quit_button_focus_entered():
	_switch_button_label_settings(%QuitButton, focusedLabel)


func _on_quit_button_focus_exited():
	if not %QuitButton.is_hovered():
		_switch_button_label_settings(%QuitButton, unfocusedLabel)


func _on_quit_button_mouse_entered():
	_switch_button_label_settings(%QuitButton, focusedLabel)


func _on_quit_button_mouse_exited():
	if not %QuitButton.has_focus():
		_switch_button_label_settings(%QuitButton, unfocusedLabel)


func _on_confirm_button_focus_entered():
	_switch_button_label_settings(%ConfirmButton, focusedLabel)


func _on_confirm_button_focus_exited():
	if not %ConfirmButton.is_hovered():
		_switch_button_label_settings(%ConfirmButton, unfocusedLabel)


func _on_confirm_button_mouse_entered():
	_switch_button_label_settings(%ConfirmButton, focusedLabel)


func _on_confirm_button_mouse_exited():
	if not %ConfirmButton.has_focus():
		_switch_button_label_settings(%ConfirmButton, unfocusedLabel)


func _on_cancel_button_focus_entered():
	_switch_button_label_settings(%CancelButton, focusedLabel)


func _on_cancel_button_focus_exited():
	if not %CancelButton.is_hovered():
		_switch_button_label_settings(%CancelButton, unfocusedLabel)


func _on_cancel_button_mouse_entered():
	_switch_button_label_settings(%CancelButton, focusedLabel)


func _on_cancel_button_mouse_exited():
	if not %CancelButton.has_focus():
		_switch_button_label_settings(%CancelButton, unfocusedLabel)
