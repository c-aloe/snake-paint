extends CanvasLayer
class_name UI

@onready var progress_bar = %FillProgress
@onready var target_percent_label = %TargetLabel
@onready var time_label = %TimeLabel
@onready var time_challenge_container = %ChallengeContainer
@onready var time_challenge_label = %TimeChallengeLabel
@onready var pause_button = %PauseButton
@onready var mute_button = %MuteButton
@onready var pause_label = %PauseLabel	# This is the text center screen when paused
var mute_texture = preload("res://assets/images/mute.png")
var unmute_texture = preload("res://assets/images/unmute.png")

signal play_button_pressed()
signal mute_button_pressed()

func _ready() -> void:
	TweenFX.pop_in(%PlayButton)

func _on_play_button_pressed() -> void:
	play_button_pressed.emit()

func _on_mute_button_pressed() -> void:
	mute_button_pressed.emit()
