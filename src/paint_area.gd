extends Node2D
class_name SnakePaintArea

'''
Ideas:
	Add a function to highlight (strobe) any unmarked cells
'''

# -------------------------------------------------
#  Export Variables
# -------------------------------------------------
@export var width: int = 150
@export var height: int = 150

@export var border_width: int = 1
@export var border_color: Color = Color(0, 0, 1)
@export var margin_size: int

@export_category("Reveal Settings")
# Note that some of these may be overridden by level settings
@export var permanent_reveal_mode: bool = false
@export var color_reveal_mode: bool = false
@export var background_color: Color = Color(randf(), randf(), randf())
@export var target_percent: float = 100.0

# -------------------------------------------------
#  Properties
# -------------------------------------------------
var paint_area_rect: Rect2
var paint_area_with_margin_rect: Rect2

var level_image: Image
var mask_image: Image
var mask_texture: ImageTexture

# Gameplay state (truth source)
var revealed: Array = []            # 2D bool array
var _revealed_count: int = 0

# Frame tracking (for temporary reveal mode)
var pixels_revealed_this_frame := {}

# -------------------------------------------------
#  Setup
# -------------------------------------------------
func setup(w, h, margin := 10) -> void:
	width = w
	height = h
	margin_size = margin

	load_level_image("res://assets/level_images/natures_best.jpg")

	_setup_paint_area()
	_initialize_revealed_grid()
	_create_mask()

func load_level_image(path: String) -> bool:
	level_image = Image.new()

	var err = level_image.load(path)
	if err != OK:
		push_error("Failed to load image: %s" % path)
		return false

	level_image.resize(width, height, Image.INTERPOLATE_NEAREST)
	level_image.convert(Image.FORMAT_RGBA8) # Fix for blit_rect error
	return true

func _setup_paint_area() -> void:
	paint_area_rect = Rect2(Vector2.ZERO, Vector2(width, height))

	paint_area_with_margin_rect = Rect2(
		Vector2(-margin_size, -margin_size),
		Vector2(width + margin_size * 2, height + margin_size * 2)
	)

func _initialize_revealed_grid() -> void:
	revealed.clear()
	_revealed_count = 0

	for x in range(width):
		revealed.append([])
		for y in range(height):
			revealed[x].append(false)

func _create_mask() -> void:
	$Background.scale = Vector2(width, height) / $Background.get_rect().size

	mask_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	mask_image.fill(Color(0,0,0,0))

	mask_texture = ImageTexture.create_from_image(mask_image)

	$RevealMask.centered = false
	$RevealMask.texture = mask_texture
	$RevealMask.position = Vector2.ZERO

func _draw() -> void:
	draw_rect(paint_area_rect, border_color, false, border_width)

# -------------------------------------------------
#  Public API
# -------------------------------------------------
func paint(snake: Snake) -> void:
	if not permanent_reveal_mode:
		_clear_previous_frame()

	for segment in range(snake.body.points.size()):
		var local = to_local(snake.body.get_point_position(segment))
		_paint_at_position(local, snake.body.width)

	mask_texture.update(mask_image)

func percent_revealed() -> int:
	@warning_ignore("narrowing_conversion")
	return (_revealed_count / float(width * height)) * 100.0

func is_filled() -> bool:
	return percent_revealed() >= target_percent

func show_full_image() -> void:
	mask_image.blit_rect(
		level_image,
		Rect2(Vector2.ZERO, level_image.get_size()),
		Vector2.ZERO
	)
	mask_texture.update(mask_image)

# -------------------------------------------------
#  Reveal Logic
# -------------------------------------------------
func _paint_at_position(local: Vector2, snake_width: float) -> void:
	# Use expanded margin rect for detection
	if not paint_area_with_margin_rect.has_point(local):
		return

	var col = int(local.x)
	var row = int(local.y)

	var radius = max(1, int(round(snake_width * 0.5)))
	_paint_pixels(col, row, radius)

func _paint_pixels(center_col: int, center_row: int, radius: int) -> void:
	for col in range(center_col - radius, center_col + radius + 1):
		for row in range(center_row - radius, center_row + radius + 1):

			if col < 0 or col >= width:
				continue
			if row < 0 or row >= height:
				continue

			var dx = col - center_col
			var dy = row - center_row

			if dx * dx + dy * dy <= radius * radius:
				_paint_pixel(col, row)

func _paint_pixel(col: int, row: int) -> void:
	# Only count if newly revealed
	if not revealed[col][row]:
		revealed[col][row] = true
		_revealed_count += 1

	var color = background_color
	if not color_reveal_mode:
		color = level_image.get_pixel(col, row)

	mask_image.set_pixel(col, row, color)

	if not permanent_reveal_mode:
		pixels_revealed_this_frame[Vector2i(col, row)] = true

func _clear_previous_frame() -> void:
	for pos in pixels_revealed_this_frame.keys():
		mask_image.set_pixel(pos.x, pos.y, Color(0,0,0,0))

		# Only revert gameplay state if not permanent
		if revealed[pos.x][pos.y]:
			revealed[pos.x][pos.y] = false
			_revealed_count -= 1

	pixels_revealed_this_frame.clear()
