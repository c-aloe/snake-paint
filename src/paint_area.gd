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

@export_category("Reveal Settings")
# Note that some of these may be overridden by level settings
@export var permanent_reveal_mode: bool = false
@export var color_reveal_mode: bool = false
@export var background_color: Color = Color(randf(), randf(), randf())

# -------------------------------------------------
#  Properties
# -------------------------------------------------
var paint_area_rect: Rect2

var level_image: Image
var mat: ShaderMaterial

# -------------------------------------------------
#  Setup
# -------------------------------------------------

func _ready() -> void:
	mat = $SubViewportContainer/SubViewport/RevealMask.material
	mat.set_shader_parameter("level_texture", $SubViewportContainer/SubViewport/RevealMask.texture)
	mat.set_shader_parameter("color_mode", color_reveal_mode)
	mat.set_shader_parameter("solid_color", background_color)

	# Link the Mask Viewport's texture to the shader
	var mask_tex = $MaskViewport.get_texture()
	mat.set_shader_parameter("mask_texture", mask_tex)
	
func setup(w, h) -> void:
	# Assign mat immediately so it's not null for the following lines
	mat = $SubViewportContainer/SubViewport/RevealMask.material

	width = w
	height = h
	$MaskViewport.size = Vector2i(width, height)
	$SubViewportContainer/SubViewport.size = Vector2i(width, height)

	# Re-Link the Mask Viewport's texture to the shader
	var mask_tex = $MaskViewport.get_texture()
	mat.set_shader_parameter("mask_texture", mask_tex)
	
	load_level_image("res://assets/level_images/natures_best.jpg")
	
	paint_area_rect = Rect2(Vector2.ZERO, Vector2(width, height))
	
	# Create mask
	$SubViewportContainer/SubViewport/RevealMask.texture = ImageTexture.create_from_image(level_image)

func load_level_image(path: String) -> bool:
	level_image = Image.new()

	var err = level_image.load(path)
	if err != OK:
		push_error("Failed to load image: %s" % path)
		return false

	level_image.resize(width, height, Image.INTERPOLATE_NEAREST)
	level_image.convert(Image.FORMAT_RGBA8) # Fix for blit_rect error
	return true

func _draw() -> void:
	draw_rect(paint_area_rect, border_color, false, border_width)
	
func percent_filled() -> float:
	# 1. Get the texture from your Viewport
	var texture = $SubViewportContainer/SubViewport.get_texture()
	
	# 2. Convert to Image data (this moves data from GPU to CPU)
	var img = texture.get_image()
	
	# 3. Use the helper to count
	var painted_pixels = _count_colored_pixels(img)
	var total_pixels = img.get_width() * img.get_height()
	
	return (float(painted_pixels) / float(total_pixels)) * 100.0

func _count_colored_pixels(img: Image) -> int:
	var count = 0
	# Optimization: If your rect is large, don't do this every frame!
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var pixel_color = img.get_pixel(x, y)
			
			# Check if the pixel has been "painted" (i.e. alpha greater than 0)
			if pixel_color.a > 0.1: 
				count += 1
				
	return count
