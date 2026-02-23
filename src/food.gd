extends Node2D
class_name Food

@onready var window_size: Vector2i = get_window().size
var random = RandomNumberGenerator.new()
	
var food: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	random.randomize()

func _draw() -> void:
	var radius := 10.0
	var color := Color(1, 0, 0) # Red color
	draw_circle(food, radius, color)
	
func check_collision(snake: Snake) -> bool:
	if snake.head.position.distance_to(food) < snake.snake_width:
		return true
	return false

func new_food() -> void:
	var x = random.randf_range(0, window_size.x)
	var y = random.randf_range(0, window_size.y)
	food = Vector2(x,y)
	print("New food at ", food)
	queue_redraw()		# So the screen redraws the food
