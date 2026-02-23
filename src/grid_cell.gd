extends Node2D
class_name GridCell

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
func deactivate():
	if not $Background.visible:
		return
		
	$Background.visible = false

func activate():
	if $Background.visible:
		return
		
	$Background.visible = true
	self_modulate.a = 1.0
	self_modulate = Color('white')
	
	$Background.scale = Vector2(0.5, 0.5)
	var tween = create_tween()
	tween.tween_property($Background, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)

	$AudioStreamPlayer2D.pitch_scale = randf_range(0.9, 1.1)
	$AudioStreamPlayer2D.play()
