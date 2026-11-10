extends Control

signal transition_requested(state: States.GameState)

@export var music: Resource
@export var unfocusedLabel: LabelSettings
@export var focusedLabel: LabelSettings

@onready var _restart_button: TextureButton = %RestartButton
@onready var _quit_button: TextureButton = %QuitButton

func _ready():
	AudioManager.play_music(music)
	%ScoreLabel.text = str(PlayerManager.get_score())
	
	if PlayerManager.get_score() > PlayerManager.get_hiscore():
		%HiscoreSprite.visible = true
	else:
		%HiscoreSprite.visible = false

func _switch_button_label_settings(button: TextureButton, settings: LabelSettings) -> void:
	if not is_instance_valid(button) or not button.is_inside_tree():
		return
	var label: Label = button.find_children("*", "Label", true, false)[0]
	label.label_settings = settings


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		transition_requested.emit(States.GameState.MAIN_MENU)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if (event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up")) and get_viewport().gui_get_focus_owner() == null:
		if is_instance_valid(_restart_button) and _restart_button.is_inside_tree():
			_restart_button.grab_focus()
			get_viewport().set_input_as_handled()


func _on_restart_button_pressed() -> void:
	transition_requested.emit(States.GameState.GAME)


func _on_quit_button_pressed() -> void:
	transition_requested.emit(States.GameState.MAIN_MENU)


func _on_restart_button_focus_entered() -> void:
	_switch_button_label_settings(_restart_button, focusedLabel)


func _on_restart_button_focus_exited() -> void:
	if is_instance_valid(_restart_button) and _restart_button.is_inside_tree() and not _restart_button.is_hovered():
		_switch_button_label_settings(_restart_button, unfocusedLabel)


func _on_restart_button_mouse_entered() -> void:
	_switch_button_label_settings(_restart_button, focusedLabel)
	get_viewport().gui_release_focus()


func _on_restart_button_mouse_exited() -> void:
	if is_instance_valid(_restart_button) and _restart_button.is_inside_tree() and not _restart_button.has_focus():
		_switch_button_label_settings(_restart_button, unfocusedLabel)


func _on_quit_button_focus_entered() -> void:
	_switch_button_label_settings(_quit_button, focusedLabel)


func _on_quit_button_focus_exited() -> void:
	if is_instance_valid(_quit_button) and _quit_button.is_inside_tree() and not _quit_button.is_hovered():
		_switch_button_label_settings(_quit_button, unfocusedLabel)


func _on_quit_button_mouse_entered() -> void:
	_switch_button_label_settings(_quit_button, focusedLabel)
	get_viewport().gui_release_focus()


func _on_quit_button_mouse_exited() -> void:
	if is_instance_valid(_quit_button) and _quit_button.is_inside_tree() and not _quit_button.has_focus():
		_switch_button_label_settings(_quit_button, unfocusedLabel)
