extends Node2D
class_name SnakePaintArea

'''
Ideas:
	Add a way to highlight (strobe) any unmarked cells
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
@export var color_reveal_mode: bool = false
@export var background_color: Color = Color(randf(), randf(), randf())

@onready var sub_viewport = %SubViewport
@onready var reveal_mask = %RevealMask

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
	mat = reveal_mask.material
	mat.set_shader_parameter("level_texture", reveal_mask.texture)
	mat.set_shader_parameter("color_mode", color_reveal_mode)
	mat.set_shader_parameter("solid_color", background_color)

	# Link the Mask Viewport's texture to the shader
	var mask_tex = $MaskViewport.get_texture()
	mat.set_shader_parameter("mask_texture", mask_tex)
	
func setup(paint_area_width: int, paint_area_height: int) -> void:
	# Assign mat immediately so it's not null for the following lines
	mat = reveal_mask.material

	width = paint_area_width
	height = paint_area_height
	$MaskViewport.size = Vector2i(width, height)
	sub_viewport.size = Vector2i(width, height)

	paint_area_rect = Rect2(Vector2.ZERO, Vector2(width, height))

	TweenFX.glow_pulse(self, 1.0, 0.02)

func animate(window_size: Vector2) -> void:
	# Needs to load the original image (have saved and just swap it out)
	remove_mask()
	
	TweenFX.stop(self, TweenFX.Animations.GLOW_PULSE)
	
	## This tween scales the image to almost full screen and centers it, but it looks terrible atm
	#var tween = get_tree().create_tween()
	#var scale_factor = (window_size.y - 120) / height
	#var paint_area_to = Vector2(
		#(window_size.x / 2.0) - (width * scale_factor) / 2.0, 
		#(window_size.y / 2.0) - (height * scale_factor) / 2.0
	#)
	#tween.tween_property(self, "scale", Vector2(scale_factor, scale_factor), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	#tween.parallel().tween_property(self, "position", paint_area_to, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	

func set_level_texture(texture: Texture2D) -> void:	
	reveal_mask.texture = texture
	reveal_mask.scale = Vector2(
		float(width) / texture.get_width(),
		float(height) / texture.get_height()
	)
	mat.set_shader_parameter("level_texture", texture)

func _draw() -> void:
	draw_rect(paint_area_rect, border_color, false, -border_width)
	
func percent_filled() -> float:
	var texture = sub_viewport.get_texture()
	
	var img = texture.get_image()
	
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

func remove_mask() -> void:
	reveal_mask.material = null
