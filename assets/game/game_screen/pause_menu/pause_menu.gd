# this class is so janky and not best practice but im on a time crunch so yolo 🤪

extends CanvasLayer

@export var unfocusedLabel: LabelSettings
@export var focusedLabel: LabelSettings
@export var pauseUnfocusedLabel: LabelSettings
@export var pauseFocusedLabel: LabelSettings

signal request_quit()

@onready var _score_label: Label = %ScoreValueLabel
@onready var _menu_panel: Control = %MenuPanel
@onready var _confirmation_panel: PanelContainer = %ConfirmationPanel
@onready var _options_button: TextureButton = %OptionsButton
var _options_normal_texture: Texture2D

func _ready() -> void:
	%VolumePanel.initialize()
	_options_normal_texture = _options_button.texture_normal
	%VolumePanel.visibility_changed.connect(_on_volume_panel_visibility_changed)

var _fade_tween: Tween

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle()
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		if %VolumePanel.visible:
			return
		if %ConfirmationPanel.visible:
			_close_confirmation_screen()
			%QuitButton.grab_focus()
		else:
			_close()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	# always allow closing; only gate opening on can_pause
	if visible:
		_close()
	else:
		_open()


func _open():
	#AudioManager.play_sfx(pause_open_sfx)
	%VolumePanel.hide()
	_fade_to(0.5, 0.4, %PauseFade)
	visible = true
	get_tree().paused = true
	%ResumeButton.grab_focus()


func _close():
	#AudioManager.play_sfx(pause_closed_sfx)
	%VolumePanel.hide()
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


func _on_resume_button_pressed():
	_close()

func _on_options_button_pressed() -> void:
	%VolumePanel.show_panel()


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

func _unhandled_key_input(event):
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
		if %MenuPanel.visible == true:
			%ResumeButton.grab_focus()
		elif %ConfirmationPanel.visible == true:
			%ConfirmButton.grab_focus()

func _on_resume_button_focus_entered():
	_switch_button_label_settings(%ResumeButton, pauseFocusedLabel)
	
func _on_resume_button_focus_exited():
	if not %ResumeButton.is_hovered():
		_switch_button_label_settings(%ResumeButton, pauseUnfocusedLabel)

func _on_resume_button_mouse_entered():
	_switch_button_label_settings(%ResumeButton, pauseFocusedLabel)
	get_viewport().gui_release_focus()

func _on_resume_button_mouse_exited():
	if not %ResumeButton.has_focus():
		_switch_button_label_settings(%ResumeButton, pauseUnfocusedLabel)


func _on_quit_button_focus_entered():
	_switch_button_label_settings(%QuitButton, pauseFocusedLabel)


func _on_quit_button_focus_exited():
	if not %QuitButton.is_hovered():
		_switch_button_label_settings(%QuitButton, pauseUnfocusedLabel)


func _on_quit_button_mouse_entered():
	_switch_button_label_settings(%QuitButton, pauseFocusedLabel)
	get_viewport().gui_release_focus()


func _on_quit_button_mouse_exited():
	if not %QuitButton.has_focus():
		_switch_button_label_settings(%QuitButton, pauseUnfocusedLabel)


func _on_confirm_button_focus_entered():
	_switch_button_label_settings(%ConfirmButton, focusedLabel)


func _on_confirm_button_focus_exited():
	if not %ConfirmButton.is_hovered():
		_switch_button_label_settings(%ConfirmButton, unfocusedLabel)


func _on_confirm_button_mouse_entered():
	_switch_button_label_settings(%ConfirmButton, focusedLabel)
	get_viewport().gui_release_focus()


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
	get_viewport().gui_release_focus()


func _on_cancel_button_mouse_exited():
	if not %CancelButton.has_focus():
		_switch_button_label_settings(%CancelButton, unfocusedLabel)

func _on_options_button_focus_entered() -> void:
	_set_options_button_highlighted(true)

func _on_options_button_focus_exited() -> void:
	_set_options_button_highlighted(_options_button.is_hovered())

func _on_options_button_mouse_entered() -> void:
	_set_options_button_highlighted(true)
	get_viewport().gui_release_focus()

func _on_options_button_mouse_exited() -> void:
	_set_options_button_highlighted(_options_button.has_focus())

func _on_volume_panel_visibility_changed() -> void:
	if %VolumePanel.visible:
		return
	call_deferred("_restore_options_button_style")

func _restore_options_button_style() -> void:
	if not is_instance_valid(_options_button) or %VolumePanel.visible:
		return
	var pointer_over_button := Rect2(_options_button.global_position, _options_button.size).has_point(_options_button.get_global_mouse_position())
	_set_options_button_highlighted(_options_button.has_focus() or pointer_over_button)

func _set_options_button_highlighted(highlighted: bool) -> void:
	_options_button.texture_normal = _options_button.texture_hover if highlighted else _options_normal_texture
	_switch_button_label_settings(_options_button, pauseFocusedLabel if highlighted else pauseUnfocusedLabel)
