extends Node2D

class_name Hub

const Utils = preload("../Utils.gd")

@onready var beer: AnimatedSprite2D = $"./Beer"
@onready var energy: AnimatedSprite2D = $"./Energy"
@onready var food: AnimatedSprite2D = $"./Food"

@export var type: Utils.BuildingType

@export var tiles: Dictionary

@export var is_build: bool = false

@export var tile_map: DungeonLayer

func set_is_build(my_is_build: bool) -> void:
	is_build = my_is_build

	if is_build:
		self.modulate.a = 1

		for tile in tiles.keys():
			var key = tile_map.world.get_unique_id(tile, tile_map.level)
			match type:
				Utils.BuildingType.BEER:
					tile_map.beer_astar.add_point(key, tile)
				Utils.BuildingType.ENERGY:
					tile_map.energy_astar.add_point(key, tile)
				Utils.BuildingType.FOOD:
					tile_map.food_astar.add_point(key, tile)
	else:
		self.modulate.a = 0.35

func init(my_type: Utils.BuildingType, my_tiles: Dictionary, my_tile_map): 
	type = my_type
	tiles = my_tiles
	match type:
		Utils.BuildingType.BEER:
			beer.visible = true
			energy.visible = false
			food.visible = false
			beer.play("default")
			energy.stop()
			food.stop()
		Utils.BuildingType.ENERGY:
			beer.visible = false
			energy.visible = true
			food.visible = false
			beer.stop()
			energy.play("default")
			food.stop()
		Utils.BuildingType.FOOD:
			beer.visible = false
			energy.visible = false
			food.visible = true
			beer.stop()
			energy.stop()
			food.play("default")
	
	tile_map = my_tile_map
	
	if tile_map:
		set_is_build(false)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
