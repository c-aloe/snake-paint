extends Resource
class_name ImageLibrary

@export var theme_name: String
@export var images: Array[Texture2D]

func get_random_texture() -> Texture2D:
	if images.is_empty():
		push_warning("ImageLibrary has no images.")
		return null
		
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return images[rng.randi_range(0, images.size() - 1)]
