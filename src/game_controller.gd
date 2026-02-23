extends Node2D
class_name GameController

'''
My idea is a Paint with Snake Game
Set a box in the middle of the screen that has to be filled by the
snake's color. Box changes shape, increases in size, etc. as levels
progress. Snake reveals an image in the paint area.
Snake gets longer and wider each time it eats food (grows)
	
Issues:
	If food is in the paint area, the grid filling stops
		- Either don't place food in paint area, or rethink why it does this
	If snake is wide enough, it can be in the paint area and not trigger painting by going really close to it
		- My idea was to establish a margin area where it will trigger the reveal mechanics if snake is in it
Features:
	"Themes" - different image packs (i.e. Christmas, family photos (yeah, plug in yuor own), nature)
	More levels
	Menu where users can
		- Set input controller
		- Choose theme
Code Improvements:
	Switch to randf()
	Make UI its own scene
	Make LevelManager its own scene
	Introduce LevelSession Node (see ChatGPT)
	Pass image in to paint area from controller
	Emit "loaded" from paint area
	Update paint area so that the head paints and tail removes
		(would need an extra case for when the snake grows while its body is on the paint area)
	Decouple paint area from snake terminology (call it circle or something instead)
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
@onready var window_size: Vector2i = get_window().size
var time_seconds: float = 0.0

var game_state: GameState
@onready var level_manager = %LevelManager
var level_data: LevelData
var current_level: int = 0	# First level load increments

const paint_scene = preload("res://scenes/paint_area.tscn")
var paint_area = null
@onready var progress_bar = %FillProgress

#endregion

func _ready() -> void:
	random.randomize()
	level_manager.connect("countdown_finished", _on_countdown_finished)	
	set_state(GameState.COUNTDOWN)

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
			level_data = _load_next_level()
			_prepare_level()
		
		GameState.PLAYING:
			_show_components(true)
			_set_paint_area()
		
		GameState.PAUSED:
			level_manager.show_pause(true)
		
		GameState.LEVEL_COMPLETE:
			paint_area.show_full_image()
			var msg = "Finished in %s" % update_ui()
			level_manager.show_level_complete("Completed", msg)

# When exiting a state
func _exit_state(state: GameState) -> void:
	match state:			
		GameState.PAUSED:
			level_manager.show_pause(false)
			
		GameState.PRE_LEVEL:
			_show_game_menu(false)

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
	
# Show or Hide snake, food, and paint area (true is show, false is hide)
func _show_components(to_show: bool) -> void:
	$Snake.visible = to_show
	$Food.visible = to_show
	if paint_area:
		paint_area.visible = to_show
	queue_redraw()

func update_ui() -> String:
	var total_seconds := int(time_seconds)
	@warning_ignore("integer_division")
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	var milliseconds := int((time_seconds - total_seconds) * 1000)

	var time_string := "%02d:%02d:%03d" % [minutes, seconds, milliseconds]

	%TimeLabel.text = time_string
	progress_bar.value = (100 - paint_area.target_percent) + paint_area.percent_revealed()

	return time_string
	
func _show_game_menu(to_show: bool) -> void:
	$UI/HUD.visible = not to_show
	$UI/GameMenu.visible = to_show
	
func _on_play_button_pressed() -> void:
	set_state(GameState.COUNTDOWN)

func _load_next_level() -> LevelData:
	current_level += 1
	return level_manager.load_level(current_level)
	
func _prepare_level():
	# Update UI
	level_manager.start_countdown()
	level_manager.show_level_intro("Level %d" % current_level, level_data.challenge)
	level_manager.visible = true
	
	# Hide actors
	_show_components(false)
	
	# Update level vars
	time_seconds = 0
	if level_data:
		$Snake.reset(
			level_data.snake_width,
			level_data.snake_width_growth_speed,
			level_data.snake_speed
		)

	# Release existing paint_area nodes
	if paint_area:
		paint_area.free()
		
	# Put food down
	$Food.new_food()
	# make sure it's not in the paint area

	
func _set_paint_area() -> void:		
	paint_area = paint_scene.instantiate()
	paint_area.setup(level_data.paint_area_width, level_data.paint_area_height)
	paint_area.position = Vector2(
		random.randi_range(0, window_size.x - paint_area.width),
		random.randi_range(45, window_size.y - paint_area.height)	# 45 allows for UI at top
	)
	paint_area.target_percent = level_data.required_completion_percentage
	add_child(paint_area)
	
	# # Move to the end of the scene tree so it's visible on top 
	# #(I opted for transparent snake instead - see _ready())
	#move_child(paint_area, get_child_count() - 1)
	#paint_area.z_index = 30
	#body.z_index = 0
	#head.z_index = 0

## Signal callable from LevelManager LevelStartTimer
func _on_countdown_finished() -> void:
	set_state(GameState.PLAYING)
	
func _physics_process(delta) -> void:
	if game_state == GameState.PLAYING:
		# Snake
		$Snake.move(delta)
		# TODO: Make this event driven? snake's move signal
		_check_snake_collisions()
		
		# Paint (if snake inside)
		paint_area.paint($Snake)
		
		if paint_area.is_filled():
			set_state(GameState.LEVEL_COMPLETE)

func _check_snake_collisions() -> void:
	# Just food for now, but will be all soon
	if $Food.check_collision($Snake):
		$Snake.grow()
		$Food.new_food()

func _process(delta):
	if game_state == GameState.PLAYING:
		time_seconds += delta
		update_ui()

func _unhandled_input(event) -> void:		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_H:
			if game_state == GameState.PLAYING:
				paint_area.show_full_image()
		elif event.keycode == KEY_SPACE:
			if game_state == GameState.LEVEL_COMPLETE:
				set_state(GameState.COUNTDOWN)
			elif game_state == GameState.COUNTDOWN:
				set_state(GameState.PLAYING)
		elif event.keycode == KEY_P:
			if game_state == GameState.PLAYING:
				set_state(GameState.PAUSED)
			elif game_state == GameState.PAUSED:
				set_state(GameState.PLAYING)
