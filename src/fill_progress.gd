extends TextureProgressBar

@onready var label = $ProgressLabel

func _on_value_changed(new_value):
	# Calculate percentage if max_value is not 100
	var percentage = (new_value / max_value) * 100
	label.text = str(int(percentage)) + "%"
