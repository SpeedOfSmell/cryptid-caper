class_name CharacterStateMachine
extends Node

const MAX_TRANSITIONS_PER_FRAME := 8 # Just to prevent infinite loops in case of faulity logic in states transitions

@export var initial_state: CharacterState

@onready var character: Character = owner

var current_state: CharacterState

func _ready():
	current_state = initial_state
	current_state.enter()

func _physics_process(delta):
	for i in MAX_TRANSITIONS_PER_FRAME:
		var next := current_state.next_state()
		if next == CharacterState.STAY:
			break
		_change_state(next)

	current_state.physics_update(delta)
	character.move_and_slide()

func _change_state(next: StringName):
	var state := get_node_or_null(NodePath(next)) as CharacterState
	assert(state != null, "State Machine has no state node named %s" % next)

	current_state.exit()
	current_state = state
	current_state.enter()
