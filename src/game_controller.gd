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

@onready var game_ui = %UI
var progress_bar
var target_label
var time_label
var time_challenge_container
var time_challenge_label
var pause_button
var mute_button

var tween: Tween

#endregion

func _ready() -> void:
	random.randomize()
	
	# References
	progress_bar = game_ui.progress_bar
	target_label = game_ui.target_percent_label
	time_label = game_ui.time_label
	time_challenge_container = game_ui.time_challenge_container
	time_challenge_label = game_ui.time_challenge_label
	pause_button = game_ui.pause_button
	mute_button = game_ui.mute_button
	
	# Signal Connections
	level_manager.connect("countdown_finished", _on_countdown_finished)	
	game_ui.connect("play_button_pressed", _on_play_button_pressed)
	game_ui.connect("mute_button_pressed", _on_mute_button_pressed)
	pause_button.connect("pressed", _pause)
	%LevelManager.next_level_button.connect("pressed", _on_next_level_button_pressed)
	
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
			time_challenge_container.visible = false
			TweenFX.stop(time_challenge_label, TweenFX.Animations.HEARTBEAT)
			_cleanup_level_session()
			current_level += 1
			level_data = level_manager.load_level(current_level)
			level_manager.prepare_level(current_level, level_data)
			if level_data.time_limit > 0:
				TweenFX.heartbeat(time_challenge_label)
			
			# Scale logo and move to top left
			var tween = get_tree().create_tween()
			tween.tween_property($Logo, "scale", Vector2(0.2, 0.2), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
			tween.parallel().tween_property($Logo, "position", Vector2(0,0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	
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
		$BackgroundMusic.volume_linear = 0.35
		set_state(GameState.PAUSED)
	elif game_state == GameState.PAUSED:
		set_state(GameState.PLAYING)
		$BackgroundMusic.volume_linear = 1.0
	
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
	
	var challenge_time = level_data.time_limit
	if challenge_time > 0:		
		time_challenge_container.visible = true
		time_challenge_label.text = "%02d" % challenge_time
		if challenge_time - total_seconds <= 10:
			if challenge_time - total_seconds <= 3:
				time_challenge_label.add_theme_color_override("font_color", Color('red'))

func _on_mute_button_pressed() -> void:
	if $BackgroundMusic.playing:
		$BackgroundMusic.stop()
	else:
		$BackgroundMusic.play()

# Signal from LevelSession
func _on_level_completed(time: float) -> void:
	level_session.paint_area.animate(get_window().size)
	var time_string = "Finished in %.3f" % time
	level_manager.show_level_complete("Completed", time_string)
	set_state(GameState.LEVEL_COMPLETE)
	
func _cleanup_level_session():
	if level_session:
		level_session.queue_free()
		level_session = null

func _on_next_level_button_pressed() -> void:
	set_state(GameState.COUNTDOWN)

func _unhandled_input(event) -> void:		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			if game_state == GameState.LEVEL_COMPLETE:
				set_state(GameState.COUNTDOWN)
			elif game_state == GameState.COUNTDOWN:
				set_state(GameState.PLAYING)
		elif event.keycode == KEY_P:
			_pause()
