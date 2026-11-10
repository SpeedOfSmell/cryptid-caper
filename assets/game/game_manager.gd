extends Node

@export var _main_menu_scene: PackedScene
@export var _tutorial_scene: PackedScene
@export var _game_scene: PackedScene
@export var _game_over_scene: PackedScene
@export var _win_scene: PackedScene

@export var button_click_sfx: SfxEvent
@export var button_focus_sfx: SfxEvent

const VALID_TRANSITIONS := {
	States.GameState.MAIN_MENU: [States.GameState.TUTORIAL],
	States.GameState.TUTORIAL: [States.GameState.MAIN_MENU, States.GameState.GAME],
	States.GameState.GAME: [States.GameState.MAIN_MENU, States.GameState.GAME_OVER, States.GameState.WIN],
	States.GameState.GAME_OVER: [States.GameState.MAIN_MENU, States.GameState.GAME],
	States.GameState.WIN: [States.GameState.MAIN_MENU, States.GameState.GAME]
}
const INITIAL_STATE := States.GameState.MAIN_MENU

var _state_machine: StateMachine
var _state_scenes: Dictionary
var _current_screen: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	_state_scenes = {
		States.GameState.MAIN_MENU: _main_menu_scene,
		States.GameState.TUTORIAL: _tutorial_scene,
		States.GameState.GAME: _game_scene,
		States.GameState.GAME_OVER: _game_over_scene,
		States.GameState.WIN: _win_scene
	}
	
	child_entered_tree.connect(_connect_ui_elements_to_audio)
	
	_state_machine = StateMachine.new(VALID_TRANSITIONS)
	_state_machine.state_changed.connect(_on_state_changed)
	_state_machine.change_state(INITIAL_STATE)

func _connect_ui_elements_to_audio(node: Node):
	if node is Button or node is TextureButton:
		node.pressed.connect(AudioManager.play_sfx.bind(button_click_sfx))
		node.focus_entered.connect(AudioManager.play_sfx.bind(button_focus_sfx))
	for child in node.get_children():
		_connect_ui_elements_to_audio(child)
		
# The screens are responsible for emitting the signal connected to this method to specify when to
# switch screens and to which screen to switch
func _on_transition_requested(state: States.GameState):
	_state_machine.change_state(state)	

# Once the state machine has verified the transition is valid, it will emit the signal connected to
# this method to signal to the game manager to make the switch
func _on_state_changed(from: int, to: int, context: Dictionary) -> void:
	_change_screen(to)

func _change_screen(state: int):
	if _current_screen:
		_current_screen.queue_free()
	
	if state == States.GameState.GAME:
		PlayerManager.new_game()
	
	_current_screen = _state_scenes[state].instantiate()
	add_child(_current_screen)

	_current_screen.transition_requested.connect(_on_transition_requested)
