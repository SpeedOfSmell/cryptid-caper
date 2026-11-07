class_name StateMachine
extends RefCounted

signal state_changed(from_state, to_state, context)

var current_state: int
var transitions: Dictionary  

#since we don't initialize with a state, make sure to set state after creation and connecting the state emit event
func _init(transition_table: Dictionary) -> void:
	current_state = -1
	transitions = transition_table

func can_transition_to(new_state: int) -> bool:
	return new_state in transitions.get(current_state, [])

func change_state(new_state: int, context: Dictionary = {}) -> bool:
	if not current_state == -1 and not can_transition_to(new_state):
		printerr("Illegal transition: %d -> %d" % [current_state, new_state])
		return false
	var old_state = current_state
	current_state = new_state
	state_changed.emit(old_state, new_state, context)
	return true
