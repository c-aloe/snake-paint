extends Node2D
class_name GameController

'''
My idea is a Paint with Snake Game
Set a box in the middle of the screen that has to be filled by the
snake's color. Box changes shape, increases in size, etc. as levels
progress. Snake reveals an image in the paint area.
Snake gets longer and wider each time it eats food (grows)
'''
enum GameState {
	PRE_LEVEL,
	COUNTDOWN,
	PLAYING,
	PAUSED,
	LEVEL_COMPLETE
}

#region Properties
var random = RandomNumberGenerator.new()

var game_state: GameState
@onready var level_manager = %LevelManager
var level_data: LevelData
var current_level: int = 0	# First level load increments
var level_session: LevelSession

@onready var progress_bar = %UI/HUD/FillProgress
@onready var target_label = %UI/HUD/TargetLabel
@onready var time_label = $UI/HUD/TimeLabel

#endregion

func _ready() -> void:
	random.randomize()
	level_manager.connect("countdown_finished", _on_countdown_finished)	
	%UI/GameMenu/PlayButton.connect("pressed", _on_play_button_pressed)
	%UI/HUD/PauseButton.connect("pressed", _pause)
	set_state(GameState.PRE_LEVEL)

func set_state(new_state: GameState):
	if not _can_transition(game_state, new_state):
		push_warning("Invalid state transition: %s -> %s" % [game_state, new_state])
		return

	_exit_state(game_state)
	game_state = new_state
	_enter_state(game_state)

# When entering a new state
func _enter_state(state: GameState):
	game_state = state
	match game_state:
		GameState.PRE_LEVEL:
			_show_game_menu(true)
		
		GameState.COUNTDOWN:
			_cleanup_level_session()
			current_level += 1
			level_data = level_manager.load_level(current_level)
			level_manager.prepare_level(current_level, level_data)
		
		GameState.PLAYING:
			pass
		
		GameState.PAUSED:
			level_manager.show_pause(true)
			level_session.is_active = false
		
		GameState.LEVEL_COMPLETE:
			# This functionality is triggered in _on_level_completed
			pass

# When exiting a state
func _exit_state(state: GameState) -> void:
	match state:
		GameState.PRE_LEVEL:
			_show_game_menu(false)
			
		GameState.COUNTDOWN:
			_start_level_session()
			
		GameState.PAUSED:
			level_manager.show_pause(false)
			level_session.is_active = true

# Transition rules
func _can_transition(from: GameState, to: GameState) -> bool:
	match from:
		GameState.PRE_LEVEL:
			return to in [GameState.PRE_LEVEL, GameState.COUNTDOWN]

		GameState.COUNTDOWN:
			return to == GameState.PLAYING

		GameState.PLAYING:
			return to in [GameState.PAUSED, GameState.LEVEL_COMPLETE]

		GameState.PAUSED:
			return to == GameState.PLAYING

		GameState.LEVEL_COMPLETE:
			return to == GameState.COUNTDOWN

	return false
	
func _show_game_menu(to_show: bool) -> void:
	$UI/HUD.visible = not to_show
	$UI/GameMenu.visible = to_show
	
func _on_play_button_pressed() -> void:
	set_state(GameState.COUNTDOWN)

func _pause() -> void:
	if game_state == GameState.PLAYING:
		set_state(GameState.PAUSED)
	elif game_state == GameState.PAUSED:
		set_state(GameState.PLAYING)	
	
## Signal callable from LevelManager LevelStartTimer
func _on_countdown_finished() -> void:
	set_state(GameState.PLAYING)

func _start_level_session():
	level_session = preload("res://scenes/level_session.tscn").instantiate()
	add_child(level_session)

	level_session.setup(level_data)
	level_session.connect("level_completed", _on_level_completed)
	level_session.connect("progress_changed", _on_progress_changed)
	level_session.connect("time_changed", _on_time_changed)

func _on_progress_changed(current_percent: float, target_percent: float) -> void:
	progress_bar.value = current_percent
	target_label.text = str(int(target_percent))

func _on_time_changed(time_seconds: float) -> void:
	var total_seconds := int(time_seconds)
	@warning_ignore("integer_division")
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	var milliseconds := int((time_seconds - total_seconds) * 1000)
	var time_string := "%02d:%02d:%03d" % [minutes, seconds, milliseconds]
	time_label.text = time_string

# Signal from LevelSession
func _on_level_completed(time: float) -> void:
	level_session.paint_area.animate()
	var time_string = "Finished in %.3f" % time
	level_manager.show_level_complete("Completed", time_string)
	set_state(GameState.LEVEL_COMPLETE)
	
func _cleanup_level_session():
	if level_session:
		level_session.queue_free()
		level_session = null

func _unhandled_input(event) -> void:		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			if game_state == GameState.LEVEL_COMPLETE:
				set_state(GameState.COUNTDOWN)
			elif game_state == GameState.COUNTDOWN:
				set_state(GameState.PLAYING)
		elif event.keycode == KEY_P:
			_pause()
