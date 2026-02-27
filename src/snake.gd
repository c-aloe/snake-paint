extends Node2D
class_name Snake

enum Controllers {
	KEYBOARD,
	MOUSE
}

#region Export Variables
@export var angular_speed: float = 5.0		# was PI
@export var input_controller: Controllers = Controllers.MOUSE
#endregion

#region Properties
var random = RandomNumberGenerator.new()
@onready var window_size: Vector2i = get_window().size

@onready var head = %SnakeHead
var head_img = Image
@onready var body = %Body

var snake_speed: float

var start_length: int = 50 # in pixels
var length: int		# Derived from start_length

var snake_width: float = 10.0
var snake_width_growth_speed: float = 0.0

#endregion

func _ready() -> void:	
	random.randomize()

	# Set up snake vars (adjust position on level start)
	head_img = head.texture.get_image()
	head.modulate.a = 0.8
	body.modulate.a = 0.5
	
func reset(width: float, width_growth_speed: float, speed: float) -> void:
	body.points = []
	length = start_length
	snake_width = width
	snake_width_growth_speed = width_growth_speed
	snake_speed = speed
	_scale_snake()
	
func _scale_snake() -> void:
	var new_scale = float(snake_width) / float(head_img.get_size().x)
	head.scale = Vector2(new_scale, new_scale)
	body.width = snake_width
	
# -------------------
#  Movement
# -------------------
#region Movement

func _direction_input() -> int:
	var direction = 0
	if Input.is_action_pressed("ui_left"):
		direction = -1
	if Input.is_action_pressed("ui_right"):
		direction = 1
	return direction


func move(delta) -> void:
	var direction: int = 0
	
	if input_controller == Controllers.KEYBOARD:
		direction = _direction_input()
		head.rotation += angular_speed * direction * delta
		
	elif input_controller == Controllers.MOUSE:
		var mouse_pos = get_global_mouse_position()
		var target_angle = (mouse_pos - head.global_position).angle()
		# Sprite faces DOWN
		head.rotation = lerp_angle(
			head.rotation,
			target_angle - PI/2,
			angular_speed * delta
		)

	var forward = Vector2.DOWN.rotated(head.rotation)
	head.position += forward * snake_speed * delta
	
	body.add_point(head.position)
	_trim_tail()
	
func grow() -> void:
	length += 50
	snake_width += snake_width_growth_speed
	_scale_snake()
	
func _trim_tail() -> void:
	var total_length := 0.0

	for i in range(body.get_point_count() - 1, 0, -1):
		var p1 = body.get_point_position(i)
		var p2 = body.get_point_position(i - 1)
		total_length += p1.distance_to(p2)

		if total_length > length:
			# remove just ONE oldest point
			body.remove_point(0)
			break
#endregion
