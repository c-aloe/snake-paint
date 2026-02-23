extends Node2D
class_name SnakePaintArea

'''
Handles:
- Grid creation
- Cell reveal logic
- Image slicing
- Fill tracking
Snake passes:
    world_position + snake_width (in pixels)
PaintArea converts internally to grid radius.

Ideas:
	Add a function to highlight (strobe) any unmarked cells
'''

# -------------------------------------------------
#  Constants / Preloads
# -------------------------------------------------
const grid_cell_scene = preload("res://scenes/grid_cell.tscn")
const image_texture = preload("res://icon.svg")

# -------------------------------------------------
#  Export Variables
# -------------------------------------------------
# width and height will be overriden by level data
@export var width: int = 150
@export var height: int = 150

@export var border_width: int = 1
@export var border_color: Color = Color(0, 0, 1)

@export var reveal_mode_permanent: bool = true
@export var target_percent: float = 100.0

# -------------------------------------------------
#  Properties
# -------------------------------------------------
var rect: Rect2

var grid: Array = []           # bool state
var reveal_grid: Array = []    # cell instances

var filled_cells: int = 0
var current_frame_cells: Array = []
var fill_percentage: int = 0
	
# -------------------------------------------------
#  Setup
# -------------------------------------------------
#region Setup

# Called from game controller (not _ready) so that width and height are available
func setup(w, h) -> void:
	width = w
	height = h
	_setup_area()
	_build_grid()
	
func _setup_area() -> void:
	rect = Rect2(Vector2.ZERO, Vector2(width, height))

func _build_grid() -> void:
	var img = image_texture.get_image()
	img.resize(width, height, Image.INTERPOLATE_BILINEAR)
	var resized_texture = ImageTexture.create_from_image(img)

	for row in range(height):
		var row_data := []
		var reveal_row := []

		for col in range(width):
			row_data.append(false)

			var cell = grid_cell_scene.instantiate()
			add_child(cell)

			var bg = cell.get_node("Background")
			bg.texture = resized_texture
			bg.region_enabled = true
			bg.region_rect = Rect2(col, row, 1, 1)
			bg.position = Vector2(col, row)
			bg.visible = false

			reveal_row.append(cell)

		grid.append(row_data)
		reveal_grid.append(reveal_row)
		

#endregion

# -------------------------------------------------
#  Drawing
# -------------------------------------------------
func _draw() -> void:
	draw_rect(rect, border_color, false, border_width)

# -------------------------------------------------
#  Public API
# -------------------------------------------------
#region Public API

func mark_grid(snake: Snake) -> bool:

	if not reveal_mode_permanent:
		_clear_previous_frame()
		
	var divider = 5
	var smaller_range = snake.body.points.size() / divider

	for segment in range(smaller_range):
		var local = to_local(snake.body.get_point_position(segment * divider))
		_mark_at_position(local, snake.body.width)

	return true
	
func _mark_at_position(local: Vector2, snake_width: float) -> void:
	if not rect.has_point(local):
		return

	var col = int(local.x)
	var row = int(local.y)

	var radius_cells = _get_radius_cells(snake_width)
	_reveal_cells(row, col, radius_cells)

func percent_filled() -> int:
	@warning_ignore("narrowing_conversion")
	return (float(filled_cells) / float(height*width)) * float(100)

func is_filled() -> bool:
	return percent_filled() >= target_percent

func show_full_image() -> void:
	for row in range(height):
		for col in range(width):
			_fill_cell(row, col)

#endregion

# -------------------------------------------------
#  Reveal Logic
# -------------------------------------------------
#region Reveal Logic

func _get_radius_cells(snake_width: float) -> int:
	return max(1, int(round(snake_width * 0.5)))

func _reveal_cells(center_row: int, center_col: int, radius: int) -> void:

	for row in range(center_row - radius, center_row + radius + 1):
		for col in range(center_col - radius, center_col + radius + 1):

			if row < 0 or row >= height:
				continue
			if col < 0 or col >= width:
				continue

			var dist = Vector2(col - center_col, row - center_row).length()

			if dist <= radius:
				_fill_cell(row, col)

func _fill_cell(row: int, col: int) -> void:
	
	if reveal_mode_permanent:
		if grid[row][col]:
			return
		grid[row][col] = true
		filled_cells += 1

	reveal_grid[row][col].activate()
	reveal_grid[row][col].modulate = Color('white')

	if not reveal_mode_permanent:
		current_frame_cells.append(Vector2i(row, col))
		
func _clear_previous_frame() -> void:
	for pos in current_frame_cells:
		reveal_grid[pos.x][pos.y].deactivate()
		reveal_grid[pos.x][pos.y].modulate = Color('white')

	current_frame_cells.clear()
	
func mark_missing_cells() -> void:
	for row in range(0, height - 1):
		for col in range(0, width - 1):
			if not grid[row][col]:
				reveal_grid[row][col].activate()
				reveal_grid[row][col].modulate.a = 0.1
				reveal_grid[row][col].modulate = Color("c70200ff")

#endregion
