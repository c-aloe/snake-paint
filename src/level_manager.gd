extends CanvasLayer
class_name LevelManager

func show_level_intro(main_text: String, subtext: String) -> void:
	level_text_main.text = main_text
	level_text_sub.text = subtext
	$LevelDisplay.visible = true
		
signal countdown_finished()
signal go_to_next_level()

@onready var timer: Timer = %LevelStartTimer
@onready var countdown_label: Label = %CountdownLabel
var countdown: int = 3

@onready var next_level_button = %NextLevelButton

@onready var level_text_main: Label = %LevelTextMain
@onready var level_text_sub: Label = %LevelTextSub

@onready var pause_label: Label = %UI/PauseLabel

var random := RandomNumberGenerator.new()


func load_level(level: int) -> LevelData:
	var level_file_path = "res://levels/level_%d.tres" % level
	
	if not ResourceLoader.exists(level_file_path):
		push_warning("Level file does not exist: %s" % level_file_path)
		return null

	var level_info := load(level_file_path)
	
	if level_info == null:
		push_error("Failed to load level resource: %s" % level_file_path)
		return null
	
	if not level_info is LevelData:
		push_error("Resource is not LevelData: %s" % level_file_path)
		return null
		
	return level_info


func generate_random_level() -> LevelData:
	random.randomize()
	
	var data := LevelData.new()
	
	# Random gameplay values
	data.snake_speed = random.randf_range(120.0, 300.0)
	data.snake_width = random.randi_range(8, 20)
	data.snake_width_growth_speed = random.randf_range(0.5, 2.0)
	
	data.paint_area_width = random.randi_range(80, 300)
	data.paint_area_height = random.randi_range(80, 300)
	
	data.required_completion_percentage = random.randf_range(60.0, 100.0)
	
	# Random reveal mode
	data.reveal_mode = LevelData.RevealMode.RANDOM
	data.challenge = "Random speed, size, etc."
	
	return data


func prepare_level(level_heading: String, level_data: LevelData) -> void:
	show_level_intro(level_heading, level_data.challenge)
	
	start_countdown()
	visible = true


func start_countdown() -> void:
	timer.start()
	next_level_button.visible = false
	countdown_label.text = str(countdown)
	countdown_label.visible = true
	

func _on_level_start_timer_timeout() -> void:
	if countdown > 1:
		#TweenFX.fade_in($LevelDisplay, 0.1)
		countdown -= 1
		countdown_label.text = str(countdown)
	else:
		timer.stop()
		countdown = 3
		#TweenFX.fade_out($LevelDisplay, 0.1)
		$LevelDisplay.visible = false
		countdown_finished.emit()
	
	#var tween = create_tween()
	#tween.tween_property($LevelDisplay, "scale", Vector2.ONE, 0.15)
	#tween.tween_property($LevelDisplay, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK)
	

func show_pause(to_show: bool) -> void:
	pause_label.visible = to_show


func show_level_complete(main_text: String, subtext: String) -> void:
	level_text_main.text = main_text
	level_text_sub.text = subtext
	countdown_label.visible = false
	$LevelDisplay.visible = true
	next_level_button.visible = true
	TweenFX.pop_in(next_level_button)


func _on_next_level_button_pressed() -> void:
	go_to_next_level.emit()


func _show_no_more_levels() -> void:
	level_text_main.text = "All Levels Complete!"
	level_text_sub.text = "Thanks for playing."
	countdown_label.visible = false
	$LevelDisplay.visible = true
	next_level_button.visible = false
