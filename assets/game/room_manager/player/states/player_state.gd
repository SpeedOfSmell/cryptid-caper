class_name PlayerState
extends Node

# Returned from next_state() to pick a state. Each value is a node name under State Machine.
const STAY := &""
const IDLE := &"Idle"
const WALK := &"Walk"
const DUCK := &"Duck"
const JUMP := &"Jump"
const FALL := &"Fall"
const COYOTE := &"Coyote"

#ADDING NEW STATE:
# 1) Add new state extending grounded, air or player state
# 2) ADd a node under the state machine, matching constant
# 3) Add constant to this script
# 4) Add rule that triggers it

# Set by the state machine.
var player: PlayerController

# Called once when this state becomes the current state.
func enter():
	pass

# Called once when another state takes over.
func exit():
	pass

# Returns the state to switch to, or STAY to remain in this one.
func next_state() -> StringName:
	return STAY

# Called every physics frame while this is the current state.
func physics_update(_delta: float):
	pass
