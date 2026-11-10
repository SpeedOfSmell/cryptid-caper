extends Control

signal transition_requested(state: States.GameState)

@export var music: Resource
@export var unfocusedLabel: LabelSettings
@export var focusedLabel: LabelSettings

@onready var _play_button: TextureButton = %PlayButton
@onready var _options_button: TextureButton = %OptionsButton
var _options_normal_texture: Texture2D

func _ready():
	AudioManager.play_music(music)
	%HiscoreLabel.text = str(PlayerManager.get_hiscore())
	_options_normal_texture = _options_button.texture_normal
	%VolumePanel.hide()
	%VolumePanel.initialize()
	%VolumePanel.visibility_changed.connect(_on_volume_panel_visibility_changed)

func _on_play_button_pressed():
	transition_requested.emit(States.GameState.TUTORIAL)

func _on_options_button_pressed():
	%VolumePanel.show_panel()

func _switch_button_label_settings(button: TextureButton, settings: LabelSettings) -> void:
	if not is_instance_valid(button) or not button.is_inside_tree():
		return
	var labels := button.find_children("*", "Label", true, false)
	if not labels.is_empty():
		labels[0].label_settings = settings

func _unhandled_key_input(event: InputEvent) -> void:
	if %VolumePanel.visible:
		return
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
		_play_button.grab_focus()

func _on_play_button_focus_entered() -> void:
	_switch_button_label_settings(_play_button, focusedLabel)

func _on_play_button_focus_exited() -> void:
	if not _play_button.is_hovered():
		_switch_button_label_settings(_play_button, unfocusedLabel)

func _on_play_button_mouse_entered() -> void:
	_switch_button_label_settings(_play_button, focusedLabel)
	get_viewport().gui_release_focus()

func _on_play_button_mouse_exited() -> void:
	if not _play_button.has_focus():
		_switch_button_label_settings(_play_button, unfocusedLabel)

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
	# The panel can cover the button, so its hover state may be stale during the
	# visibility_changed callback. Restore after hit testing updates, starting in
	# the normal black-on-light state. A fresh hover/focus event applies highlight.
	call_deferred("_restore_options_button_style")

func _restore_options_button_style() -> void:
	if not is_instance_valid(_options_button) or %VolumePanel.visible:
		return
	var pointer_over_button := Rect2(_options_button.global_position, _options_button.size).has_point(get_global_mouse_position())
	_set_options_button_highlighted(_options_button.has_focus() or pointer_over_button)

func _set_options_button_highlighted(highlighted: bool) -> void:
	# Keep label contrast coupled to the matching normal/hover button texture.
	_options_button.texture_normal = _options_button.texture_hover if highlighted else _options_normal_texture
	_switch_button_label_settings(_options_button, focusedLabel if highlighted else unfocusedLabel)
