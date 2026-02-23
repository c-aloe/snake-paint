#extends Resource
#class_name LevelData
#
#@export var level_scene: PackedScene
#@export var data: Dictionary = {
	#"paint_area_width": 0,
	#"paint_area_height": 0,
	#"snake_width": 0,
	#"snake_width_growth_speed": 0,
	#"challenge": ""
#}

extends Resource
class_name LevelData

@export var level_scene: PackedScene

@export_group("Paint Area")
@export var paint_area_width: int
@export var paint_area_height: int
@export var required_completion_percentage: float = 100.0

@export_group("Snake")
@export var snake_speed: int
@export var snake_width: float
@export var snake_width_growth_speed: float

@export_group("Meta")
@export var challenge: String

@export_group("Unused")
@export var time_limit: float = 0.0  # 0 = no limit
#@export_group("Advanced")
@export var obstacles: Array[Vector2] = []
@export var growth_enabled: bool = true
@export var reveal_multiplier: float = 1.0
