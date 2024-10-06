extends Node2D

class_name BuildingCursor

const Utils = preload("./Utils.gd")

@onready var game_state: GameState = $"/root/Game/GameState"
@onready var world: World = $"/root/Game/World"

@onready var indicator: TileMap = $"./IndicatorMap"
@onready var blueprint_beer: AnimatedSprite2D = $"./Blueprint_beer"
@onready var blueprint_energy: AnimatedSprite2D = $"./Blueprint_energy"
@onready var blueprint_food: AnimatedSprite2D = $"./Blueprint_food"

@export var building_type: Utils.BuildingType = Utils.BuildingType.BEER

@export var space_is_free: bool = false
@export var has_resources: bool = false
@export var can_build: bool = false

@export var energy_cost_dirt = 0
@export var energy_cost_stone = 5
@export var energy_cost_iron = 5
@export var energy_cost_copper = 0
@export var energy_cost_water = 5
@export var energy_cost_micel = 0
@export var energy_cost_wealth = 0

@export var food_cost_dirt = 0
@export var food_cost_stone = 0
@export var food_cost_iron = 0
@export var food_cost_copper = 0
@export var food_cost_water = 0
@export var food_cost_micel = 10
@export var food_cost_wealth = 0

@export var beer_cost_dirt = 0
@export var beer_cost_stone = 0
@export var beer_cost_iron = 5
@export var beer_cost_copper = 0
@export var beer_cost_water = 5
@export var beer_cost_micel = 0
@export var beer_cost_wealth = 0

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

	set_can_build(evaluate_has_resouces(), is_free)

	var new_coords = world.visible_tile_map.map_to_local(new_pos)
	var offset = Vector2(-Utils.TILE_SIZE_HALF, -Utils.TILE_SIZE_HALF)
	position = new_coords + offset

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	set_can_build(evaluate_has_resouces())

func set_can_build(my_has_resouces: bool, my_space_is_free: bool = space_is_free) -> void:
	has_resources = my_has_resouces
	space_is_free = my_space_is_free
	can_build = has_resources and space_is_free

	if can_build:
		blueprint_beer.modulate.r = 1
		blueprint_energy.modulate.r = 1
		blueprint_food.modulate.r = 1
	else:
		blueprint_beer.modulate.r = 10
		blueprint_energy.modulate.r = 10
		blueprint_food.modulate.r = 10
	
func evaluate_has_resouces() -> bool:
	match building_type:
		Utils.BuildingType.ENERGY:
			return game_state.dirt >= energy_cost_dirt and \
				game_state.stone >= energy_cost_stone and \
				game_state.iron >= energy_cost_iron and \
				game_state.copper >= energy_cost_copper and \
				game_state.water >= energy_cost_water and \
				game_state.micel >= energy_cost_micel and \
				game_state.wealth >= energy_cost_wealth
		Utils.BuildingType.FOOD:
			return game_state.dirt >= food_cost_dirt and \
				game_state.stone >= food_cost_stone and \
				game_state.iron >= food_cost_iron and \
				game_state.copper >= food_cost_copper and \
				game_state.water >= food_cost_water and \
				game_state.micel >= food_cost_micel and \
				game_state.wealth >= food_cost_wealth
		Utils.BuildingType.BEER:
			return game_state.dirt >= beer_cost_dirt and \
				game_state.stone >= beer_cost_stone and \
				game_state.iron >= beer_cost_iron and \
				game_state.copper >= beer_cost_copper and \
				game_state.water >= beer_cost_water and \
				game_state.micel >= beer_cost_micel and \
				game_state.wealth >= beer_cost_wealth
		_:
			return false
