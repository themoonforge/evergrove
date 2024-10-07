extends Node2D

class_name BuildingCursor

const Utils = preload("./Utils.gd")

@onready var game_state: GameState = $"/root/Game/GameState"
@onready var world: World = $"/root/Game/World"

@onready var indicator: TileMap = $"./IndicatorMap"
@onready var hub: Hub = $"./Hub"
@onready var labelContainer: VFlowContainer = $"./LabelContainer"

@export var building_type: Utils.BuildingType = Utils.BuildingType.BEER

@export var space_is_free: bool = false
@export var has_resources: bool = false
@export var can_build: bool = false

@export var energy_cost_dirt = 10
@export var energy_cost_stone = 1
@export var energy_cost_iron = 1
@export var energy_cost_copper = 0
@export var energy_cost_water = 0
@export var energy_cost_micel = 0
@export var energy_cost_wealth = 0

@export var food_cost_dirt = 10
@export var food_cost_stone = 0
@export var food_cost_iron = 0
@export var food_cost_copper = 0
@export var food_cost_water = 0
@export var food_cost_micel = 1
@export var food_cost_wealth = 0

@export var beer_cost_dirt = 10
@export var beer_cost_stone = 1
@export var beer_cost_iron = 1
@export var beer_cost_copper = 0
@export var beer_cost_water = 0
@export var beer_cost_micel = 0
@export var beer_cost_wealth = 0

@export var ignore_recource_costs: bool = true

@export var tiles: Dictionary = {}

func set_building_type(type: Utils.BuildingType) -> void:
	building_type = type
	hub.init(type, {}, null)
	eval_cost_labels()

func eval_cost_labels() -> void:
	for child in labelContainer.get_children():
		child.queue_free()
	match building_type:
		Utils.BuildingType.ENERGY:
			_create_cost_label("Dirt", energy_cost_dirt, game_state.dirt)
			_create_cost_label("Stone", energy_cost_stone, game_state.stone)
			_create_cost_label("Iron", energy_cost_iron, game_state.iron)
			_create_cost_label("Copper", energy_cost_copper, game_state.copper)
			_create_cost_label("Water", energy_cost_water, game_state.water)
			_create_cost_label("Micel", energy_cost_micel, game_state.micel)
			_create_cost_label("Wealth", energy_cost_wealth, game_state.wealth)
		Utils.BuildingType.FOOD:
			_create_cost_label("Dirt", food_cost_dirt, game_state.dirt)
			_create_cost_label("Stone", food_cost_stone, game_state.stone)
			_create_cost_label("Iron", food_cost_iron, game_state.iron)
			_create_cost_label("Copper", food_cost_copper, game_state.copper)
			_create_cost_label("Water", food_cost_water, game_state.water)
			_create_cost_label("Micel", food_cost_micel, game_state.micel)
			_create_cost_label("Wealth", food_cost_wealth, game_state.wealth)
		Utils.BuildingType.BEER:
			_create_cost_label("Dirt", beer_cost_dirt, game_state.dirt)
			_create_cost_label("Stone", beer_cost_stone, game_state.stone)
			_create_cost_label("Iron", beer_cost_iron, game_state.iron)
			_create_cost_label("Copper", beer_cost_copper, game_state.copper)
			_create_cost_label("Water", beer_cost_water, game_state.water)
			_create_cost_label("Micel", beer_cost_micel, game_state.micel)
			_create_cost_label("Wealth", beer_cost_wealth, game_state.wealth)
		_:
			print("Unknown building type: ", building_type)
	pass

func _create_cost_label(resource_name: String, cost: int, available: int) -> void:
	if cost > 0:
		var label = Label.new()
		label.text = str(cost) + " " + resource_name
		if available < cost:
			label.modulate = Color8(255, 0, 0)
			
		labelContainer.add_child(label)

func set_tile(pos: Vector2i) -> void:
	indicator.clear()
	var new_pos = pos + Vector2i(-1, -1)
	
	var is_free: bool = true

	var my_tiles = {}

	for x in range(0, 3):
		for y in range(0, 3):
			var incidator_offset = Vector2i(x, y)
			var tile = new_pos + incidator_offset
			my_tiles[tile] = true
			var free = world.is_free_space(tile)
			if !free:
				is_free = false
				indicator.set_cell(0, incidator_offset, 0, Vector2i(0, 0))

	set_can_build(evaluate_has_resouces(), is_free)

	var new_coords = world.visible_tile_map.map_to_local(new_pos)
	var offset = Vector2(-Utils.TILE_SIZE_HALF, -Utils.TILE_SIZE_HALF)
	position = new_coords + offset
	tiles = my_tiles

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	set_can_build(evaluate_has_resouces())

func set_can_build(my_has_resouces: bool, my_space_is_free: bool = space_is_free) -> void:
	has_resources = my_has_resouces || ignore_recource_costs
	space_is_free = my_space_is_free
	can_build = has_resources and space_is_free

	if can_build:
		hub.modulate.r = 1
	else:
		hub.modulate.r = 10
	
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

func build() -> void:
	if can_build:
		match building_type:
			Utils.BuildingType.ENERGY:
				game_state.dec_dirt(energy_cost_dirt)
				game_state.dec_stone(energy_cost_stone)
				game_state.dec_iron(energy_cost_iron)
				game_state.dec_copper(energy_cost_copper)
				game_state.dec_water(energy_cost_water)
				game_state.dec_micel(energy_cost_micel)
				game_state.dec_wealth(energy_cost_wealth)
			Utils.BuildingType.FOOD:
				game_state.dec_dirt(food_cost_dirt)
				game_state.dec_stone(food_cost_stone)
				game_state.dec_iron(food_cost_iron)
				game_state.dec_copper(food_cost_copper)
				game_state.dec_water(food_cost_water)
				game_state.dec_micel(food_cost_micel)
				game_state.dec_wealth(food_cost_wealth)
			Utils.BuildingType.BEER:
				game_state.dec_dirt(beer_cost_dirt)
				game_state.dec_stone(beer_cost_stone)
				game_state.dec_iron(beer_cost_iron)
				game_state.dec_copper(beer_cost_copper)
				game_state.dec_water(beer_cost_water)
				game_state.dec_micel(beer_cost_micel)
				game_state.dec_wealth(beer_cost_wealth)
			_:
				pass

		world.build_building(building_type, position, tiles)
