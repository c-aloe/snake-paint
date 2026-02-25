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
@onready var window_size: Vector2i = get_window().size
var time_seconds: float = 0.0

var game_state: GameState
@onready var level_manager = %LevelManager
var level_data: LevelData
var current_level: int = 0	# First level load increments

const paint_scene = preload("res://scenes/paint_area.tscn")
var paint_area = null
@onready var progress_bar = %FillProgress

@export var target_percent: float = 100.0

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
			$Food.visible = false
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
	#var area_inside = paint_area.snake_area_inside($Snake.body, $Snake.snake_width)
	progress_bar.value = paint_area.percent_filled()

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

	
func _set_paint_area() -> void:		
	paint_area = paint_scene.instantiate()
	paint_area.setup(level_data.paint_area_width, level_data.paint_area_height)
	paint_area.position = Vector2(
		random.randi_range(0, window_size.x - paint_area.width),
		random.randi_range(45, window_size.y - paint_area.height)	# 45 allows for UI at top
	)
	target_percent = level_data.required_completion_percentage
	add_child(paint_area)

## Signal callable from LevelManager LevelStartTimer
func _on_countdown_finished() -> void:
	set_state(GameState.PLAYING)

func get_snake_length() -> float:
	var body = $Snake.body
	var total := 0.0
	for i in range(body.get_point_count() - 1):
		total += body.get_point_position(i).distance_to(
			body.get_point_position(i + 1)
		)
	return total

func _physics_process(delta) -> void:
	if game_state != GameState.PLAYING:
		return
		
	# Snake
	$Snake.move(delta)
	# TODO: Make this event driven? snake's move signal
	_food_snake_collisions()
	
	update_snake_mask($Snake.body)
	
	if paint_area.percent_filled() >= target_percent:
		set_state(GameState.LEVEL_COMPLETE)
	
		
'''		var body = $Snake.body
		var point_count = body.get_point_count()

		if point_count == 0:
			return

		var head_point = body.get_point_position(point_count - 1)
		var current_tail = body.get_point_position(0)
		
		# If tail moved, erase the previous one
		if previous_tail_point != Vector2.ZERO and current_tail != previous_tail_point:
			paint_area.erase_segment(previous_tail_point, current_tail, $Snake.snake_width)
		
		paint_area.paint_head(head_point, $Snake.snake_width)

		previous_tail_point = current_tail
		
		
		
		
		
		## Paint (if snake inside)
		## Only use the head to draw (not all the body segments)
		#paint_area.paint($Snake.body.points[-1], $Snake.snake_width)
		##if _tail_in_paint_area():
			##paint_area.paint($Snake.body.points[0], $Snake.snake_width)
		###paint_area.paint($Snake)'''
			
			
func _update_shader_snake():
	var body = $Snake.body
	var count = body.get_point_count()
	const MAX_SHADER_POINTS := 128

	if count < 2:
		return

	var mat := paint_area.mat as ShaderMaterial
	
	var start_index = max(0, count - MAX_SHADER_POINTS)

	var points := []
	for i in range(start_index, count):
		var local = paint_area.to_local(body.get_point_position(i))
		points.append(local)
		
	var actual_count = points.size()

	mat.set_shader_parameter("snake_points", points)
	mat.set_shader_parameter("snake_point_count", actual_count)
	mat.set_shader_parameter("snake_radius", $Snake.snake_width * 0.5)

# Call this whenever the snake moves
func update_snake_mask(body: Line2D):
	var mask_line = paint_area.get_node("MaskViewport/SnakeMaskLine")
	var local_points = []
	for p in $Snake.body.points:
		local_points.append(paint_area.to_local(p))
	mask_line.points = PackedVector2Array(local_points)
	mask_line.width = body.width
	
			
func _tail_in_paint_area() -> bool:
	var tail_end = $Snake.body.points[0]
	var x_start: int = paint_area.position.x - $Snake.snake_width / 2
	var x_end: int = paint_area.position.x + paint_area.width + $Snake.snake_width / 2
	var y_start = paint_area.position.y - $Snake.snake_width / 2
	var y_end = paint_area.position.y + paint_area.height + $Snake.snake_width / 2
	if tail_end.x > x_start and tail_end.x < x_end:
		if tail_end.y > y_start and tail_end.y < y_end:
			return true
	return false
	

func _food_snake_collisions() -> void:
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
