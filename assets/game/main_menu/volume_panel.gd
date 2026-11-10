extends Control

const MAX_VOLUME := 10
const BUS_ORDER: Array[int] = [AudioManager.Bus.MASTER, AudioManager.Bus.SFX, AudioManager.Bus.MUSIC]
const ROW_NAMES := ["Master", "Sfx", "Music"]

var selected_index := 0
var volumes: Array[int] = [10, 10, 10]

func initialize() -> void:
	for i in BUS_ORDER.size():
		volumes[i] = roundi(AudioManager.get_bus_volume(BUS_ORDER[i]) * MAX_VOLUME)
	_refresh_rows()

func show_panel() -> void:
	show()
	selected_index = 0
	_refresh_rows()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_up"):
		selected_index = wrapi(selected_index - 1, 0, 4)
		_refresh_rows()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		selected_index = wrapi(selected_index + 1, 0, 4)
		_refresh_rows()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		if selected_index < 3:
			_adjust_volume(selected_index, -1 if event.is_action_pressed("ui_left") else 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		if selected_index == 3:
			hide()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()

func _on_volume_row_gui_input(event: InputEvent, row_index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected_index = row_index
		if row_index < 3:
			var rows: Array[Label] = [%MasterVolume, %SfxVolume, %MusicVolume]
			var row := rows[row_index]
			_adjust_volume(row_index, -1 if event.position.x < row.size.x / 2.0 else 1)
		else:
			hide()
		_refresh_rows()
		accept_event()

func _adjust_volume(index: int, amount: int) -> void:
	volumes[index] = clampi(volumes[index] + amount, 0, MAX_VOLUME)
	AudioManager.set_bus_volume(BUS_ORDER[index], float(volumes[index]) / MAX_VOLUME)
	_refresh_rows()

func _refresh_rows() -> void:
	var labels: Array[Label] = [%MasterVolume, %SfxVolume, %MusicVolume]
	for i in labels.size():
		labels[i].text = ("< %s: %d >" if selected_index == i else "[ %s: %d ]") % [ROW_NAMES[i], volumes[i]]
	%CloseButton.text = "< Close >" if selected_index == 3 else "Close"
