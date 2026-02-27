extends Node2D
class_name Food

@onready var window_size: Vector2i = get_window().size
var random := RandomNumberGenerator.new()

var food: Vector2 = Vector2.ZERO
var food_radius := 10.0
	
func _ready() -> void:
	random.randomize()

func _draw() -> void:
	pass
	#draw_circle(food, food_radius, Color(1, 0, 0))

func check_collision(snake: Snake) -> bool:
	return snake.head.position.distance_to(food) < snake.snake_width

# -------------------------------------------------
#  Spawn Logic
# -------------------------------------------------

func new_food() -> void:
	var x = random.randf_range(0, window_size.x)
	var y = random.randf_range(0, window_size.y)
	food = Vector2(x,y)
	queue_redraw()
	$Sprite2D.position = food
	await TweenFX.fade_in(self).finished
	TweenFX.float_bob(self, 0.5, 1)

'''
func new_food_avoiding_paint_area(paint_area: SnakePaintArea) -> void:
	var attempts := 0
	var max_attempts := 1000
	
	while attempts < max_attempts:
		attempts += 1
		
		var x = random.randf_range(0, window_size.x)
		var y = random.randf_range(0, window_size.y)
		var candidate := Vector2(x, y)
		
		if not paint_area:
			food = candidate
			queue_redraw()
			return
			
		# Convert to paint area local space
		var local := paint_area.to_local(candidate)
		
		# If NOT inside paint area + margin, accept
		if not paint_area.paint_area_with_margin_rect.has_point(local):
			food = candidate
			queue_redraw()
			return
	
	push_warning("Failed to place food outside paint area after many attempts.")
'''
