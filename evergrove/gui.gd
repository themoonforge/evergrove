extends CanvasLayer

class_name GUI

const Utils = preload("./Utils.gd")

@onready var game_state: GameState = $/root/Game/GameState
@onready var world: World = $/root/Game/World
@onready var factory = $/root/Game/Factory

@export var spawn_position:Vector2i

@onready var level_label: Label = $"./VFlowContainer/LevelLabel"
@onready var dirt_label: Label = $"./VFlowContainer/DirtLabel"
@onready var stone_label: Label = $"./VFlowContainer/StoneLabel"
@onready var iron_label: Label = $"./VFlowContainer/IronLabel"
@onready var copper_label: Label = $"./VFlowContainer/CopperLabel"
@onready var wealth_label: Label = $"./VFlowContainer/WealthLabel"
@onready var micel_label: Label = $"./VFlowContainer/MicelLabel"
@onready var water_label: Label = $"./VFlowContainer/WaterLabel"
@onready var dwarf_label: Label = $"./VFlowContainer/DwarfLabel"

@onready var spawn_dwarf_button: Button = $"./VFlowContainer2/SpawnDwarfButton"
@onready var up_button: Button = $"./HSplitContainer/UpButton"
@onready var down_button: Button = $"./HSplitContainer/DownButton"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_spawn_dwarf_button_pressed():
	if game_state.wealth < game_state.dwarf_spawn_cost:
		return
	
	game_state.dec_wealth(game_state.dwarf_spawn_cost)

	var dungeon_layer_index = 0 # TODO use correct dungeon  layer
	var position = spawn_position # TODO use correct position
	
	var dungeon_layer = world.tile_maps[dungeon_layer_index]
	var dwarf_container = dungeon_layer.dwarf_container
	
	var dwarf: Dwarf = preload("res://dwarf/Dwarf.tscn").instantiate()
	dwarf_container.add_child(dwarf)
	dwarf.current_dungeon_layer = dungeon_layer
	dwarf.set_current_position(position, dungeon_layer_index, true)
	dwarf.position = dungeon_layer.map_to_local(position) # TODO convert to map position

func _on_spawn_energy_hub_button_pressed():
	var dungeon_layer_index = 0 # TODO use correct dungeon  layer
	var position = spawn_position # TODO use correct position
	
	var dungeon_layer = world.tile_maps[dungeon_layer_index]
	var hub_container = dungeon_layer.hub_container
	
	var energy_hub = preload("res://hubs/EnergyHub.tscn").instantiate()
	hub_container.add_child(energy_hub)
	energy_hub.position = dungeon_layer.map_to_local(position) # TODO convert to map position

# Setter methods for label members
func set_label_dirt(value: String) -> void:
	dirt_label.text = "Dirt: %s" % [value]

func set_label_stone(value: String) -> void:
	stone_label.text = "Stone: %s" % [value]

func set_label_iron(value: String) -> void:
	iron_label.text = "Iron: %s" % [value]

func set_label_copper(value: String) -> void:
	copper_label.text = "Copper: %s" % [value]

func set_label_wealth(value: String) -> void:
	wealth_label.text = "Wealth: %s" % [value]

func set_label_water(value: String) -> void:
	water_label.text = "Water: %s" % [value]

func set_label_micel(value: String) -> void:
	micel_label.text = "Micel: %s" % [value]

func set_label_dwarf(value: String) -> void:
	dwarf_label.text = "Dwarf: %s" % [value]

func set_label_current_level(value: String) -> void:
	level_label.text = "Layer: %s" % [value]
	
func _on_food_hub_button_pressed():
	world.set_cursor_type(Utils.CursorType.BUILD, Utils.BuildingType.FOOD)

func _on_beer_hub_button_pressed():
	world.set_cursor_type(Utils.CursorType.BUILD, Utils.BuildingType.BEER)

func _on_energy_hub_button_pressed():
	world.set_cursor_type(Utils.CursorType.BUILD, Utils.BuildingType.ENERGY)

func set_spawn_cost(value: int) -> void:
	if value > 0:
		spawn_dwarf_button.text = "Spawn Dwarf (" + str(value) + " $)"	
	else:
		spawn_dwarf_button.text = "Spawn Dwarf (free)"



func _on_up_button_pressed() -> void:
	world.set_active_level(world.visible_level - 1)

func _on_down_button_pressed() -> void:
	world.set_active_level(world.visible_level + 1)
