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
@export var margin_size := 0

@export_category("Reveal Settings")
# Note that some of these may be overridden by level settings
@export var permanent_reveal_mode: bool = false
@export var color_reveal_mode: bool = false
@export var background_color: Color = generate_random_rgb_color()
@export var target_percent: float = 100.0

# -------------------------------------------------
#  Properties
# -------------------------------------------------
var paint_area_rect: Rect2
var paint_area_margins: Rect2

var level_image: Image
var mask_image: Image
var mask_texture: ImageTexture

# Gameplay state (truth source)
var revealed: Array = []            # 2D bool array
var _revealed_count: int = 0

# Frame tracking (for temporary reveal mode)
var pixels_revealed_this_frame := {}   # Dictionary used as a Set

# -------------------------------------------------
#  Setup
# -------------------------------------------------
#region Setup

func setup(w, h, margin := 0) -> void:
	width = w
	height = h
	margin = 10
	paint_area_margins = Rect2(
		global_position - Vector2(margin, margin), 
		Vector2(width + (margin*2), height + (margin*2))
	)
	
	load_level_image("res://assets/level_images/natures_best.jpg") # TODO: pass from controller
	_setup_paint_area()
	_initialize_revealed_grid()
	_create_mask()
	print(paint_area_margins)
	
func generate_random_rgb_color() -> Color:
	# Generates a random color with full alpha (opaque)
	return Color(
		randf(), # Red channel (0.0 to 1.0)
		randf(), # Green channel (0.0 to 1.0)
		randf()  # Blue channel (0.0 to 1.0)
	)

func load_level_image(path: String) -> bool:
	level_image = Image.new()
	
	var err = level_image.load(path)
	if err != OK:
		push_error("Failed to load image: %s" % path)
		return false
		
	level_image.resize(width, height, Image.INTERPOLATE_NEAREST)
	return true

func _setup_paint_area() -> void:
	paint_area_rect = Rect2(Vector2.ZERO, Vector2(width, height))

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

#endregion

func _draw() -> void:
	#draw_rect(paint_area_margins, Color(1,1,1,0.5))
	draw_rect(paint_area_rect, border_color, false, border_width)

# -------------------------------------------------
#  Public API
# -------------------------------------------------
#region Public API

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

#endregion

# -------------------------------------------------
#  Reveal Logic
# -------------------------------------------------
#region Reveal Logic

func _paint_at_position(local: Vector2, snake_width: float) -> void:
	if not paint_area_rect.has_point(local):
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

			var dist = Vector2(col - center_col, row - center_row).length()
			if dist <= radius:
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

#endregion
