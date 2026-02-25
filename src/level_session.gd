extends Node2D
class_name LevelSession

const SNAKE_SCENE = preload("res://scenes/snake.tscn")
const FOOD_SCENE = preload("res://scenes/food.tscn")
const PAINT_AREA_SCENE = preload("res://scenes/paint_area.tscn")

signal level_completed(time: float)
signal progress_changed(current: float, target: float)
signal time_changed(time: float)

var random = RandomNumberGenerator.new()
var window_size: Vector2i:
	get:
		return get_viewport_rect().size

var level_data: LevelData
@export var image_library: ImageLibrary
var is_active := false

var target_percent: float = 100.0
var progress_bar
var target_label
var time_label
var time: float

var snake: Snake
var food: Food
var paint_area: SnakePaintArea

func setup(data: LevelData) -> void:
	random.randomize()
	time = 0.0
	
	level_data = data
	target_percent = data.required_completion_percentage

	_create_components()
	_configure_from_level_data()
	is_active = true
	
func _create_components() -> void:
	paint_area = PAINT_AREA_SCENE.instantiate()
	food = FOOD_SCENE.instantiate()
	snake = SNAKE_SCENE.instantiate()
	
	add_child(paint_area)
	add_child(food)
	add_child(snake)

func _configure_from_level_data() -> void:
	# Setup paint area
	paint_area.setup(
		level_data.paint_area_width,
		level_data.paint_area_height
	)
	paint_area.position = Vector2(
		random.randi_range(0, window_size.x - paint_area.width),
		random.randi_range(45, window_size.y - paint_area.height)	# 45 allows for UI at top
	)
	var texture := image_library.get_random_texture()
	if texture:
		paint_area.set_level_texture(texture)
	else:
		paint_area.color_reveal_mode = true

	# Setup snake
	snake.reset(
		level_data.snake_width,
		level_data.snake_width_growth_speed,
		level_data.snake_speed
	)

	# Spawn food
	food.new_food()
	
func _physics_process(delta):
	if is_active:
		time += delta

		snake.move(delta)
		_handle_food_collision()
		_update_snake_mask(snake.body)
		
		var current_percent := paint_area.percent_filled()
		
		emit_signal("progress_changed", current_percent, target_percent)
		emit_signal("time_changed", time)

		if current_percent >= target_percent:
			is_active = false
			emit_signal("level_completed", time)

# Call this whenever the snake moves
func _update_snake_mask(body: Line2D):
	var mask_line = paint_area.get_node("MaskViewport/SnakeMaskLine")
	var local_points = []
	for p in snake.body.points:
		local_points.append(paint_area.to_local(p))
	mask_line.points = PackedVector2Array(local_points)
	mask_line.width = body.width

func _handle_food_collision():
	if food.check_collision(snake):
		snake.grow()
		food.new_food()
