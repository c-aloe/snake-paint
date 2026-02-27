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

func load_level(level: int) -> LevelData:
	var level_file_path = "res://levels/level_%d.tres" % level
	var level_info = load(level_file_path)
	return level_info
	
func prepare_level(current_level: int, level_data: LevelData) -> void:
	start_countdown()
	show_level_intro("Level %d" % current_level, level_data.challenge)
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
