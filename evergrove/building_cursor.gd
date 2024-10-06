extends Node2D

class_name BuildingCursor

const Utils = preload("./Utils.gd")

@onready var world: World = $"/root/Game/World"

@onready var indicator: TileMap = $"./IndicatorMap"
@onready var blueprint_beer: AnimatedSprite2D = $"./Blueprint_beer"
@onready var blueprint_energy: AnimatedSprite2D = $"./Blueprint_energy"
@onready var blueprint_food: AnimatedSprite2D = $"./Blueprint_food"

@export var building_type: Utils.BuildingType = Utils.BuildingType.BEER

func set_building_type(type: Utils.BuildingType) -> void:
	building_type = type
	blueprint_beer.visible = building_type == Utils.BuildingType.BEER
	blueprint_energy.visible = building_type == Utils.BuildingType.ENERGY
	blueprint_food.visible = building_type == Utils.BuildingType.FOOD

func set_tile(pos: Vector2i) -> void:
	indicator.clear()
	var new_pos = pos + Vector2i(-1, -1)
	
	var is_free: bool = true

	for x in range(0, 3):
		for y in range(0, 3):
			var incidator_offset = Vector2i(x, y)
			var free = world.is_free_space(new_pos + incidator_offset)
			if !free:
				is_free = false
				indicator.set_cell(0, incidator_offset, 0, Vector2i(0, 0))

	if is_free:
		blueprint_beer.modulate.r = 1
		blueprint_energy.modulate.r = 1
		blueprint_food.modulate.r = 1
	else:
		blueprint_beer.modulate.r = 10
		blueprint_energy.modulate.r = 10
		blueprint_food.modulate.r = 10

	var new_coords = world.visible_tile_map.map_to_local(new_pos)
	var offset = Vector2(-Utils.TILE_SIZE_HALF, -Utils.TILE_SIZE_HALF)
	position = new_coords + offset

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
