extends Node

class_name GameState

@onready var gui = get_node("/root/Game/GUI")

@export var dirt = 0
@export var stone = 0
@export var coal = 0
@export var iron = 0
@export var copper = 0
@export var silver = 0
@export var gold = 0
@export var gem = 0
@export var water = 0
@export var micel = 0

@export var wealth = 0

@export var current_level = 0

@export var silver_factor = 1
@export var gold_factor = 10
@export var gem_factor = 100

@export var selected_dwarf: Dwarf

# Setter methods
func set_dirt(value: int) -> void:
	dirt = value
	gui.set_label_dirt(str(dirt))

func set_stone(value: int) -> void:
	stone = value
	gui.set_label_stone(str(stone))

func set_coal(value: int) -> void:
	coal = value

func set_iron(value: int) -> void:
	iron = value
	gui.set_label_iron(str(iron))

func set_copper(value: int) -> void:
	copper = value
	gui.set_label_copper(str(copper))

func set_silver(value: int) -> void:
	silver = value
	set_wealth(calc_wealth())

func set_gold(value: int) -> void:
	gold = value
	set_wealth(calc_wealth())

func set_gem(value: int) -> void:
	gem = value
	set_wealth(calc_wealth())

func set_water(value: int) -> void:
	water = value
	gui.set_label_water(str(water))

func set_micel(value: int) -> void:
	micel = value
	gui.set_label_micel(str(micel))

func set_wealth(value: int) -> void:
	wealth = value
	gui.set_label_wealth(str(wealth))

func set_current_level(value: int) -> void:
	current_level = value
	gui.set_lavel_current_level(str(current_level))

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_coal(0)
	set_copper(0)
	set_dirt(0)
	set_gem(0)
	set_gold(0)
	set_stone(0)
	set_silver(0)
	set_water(0)
	set_micel(0)
	set_iron(0)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func calc_wealth() -> int:
	return silver * silver_factor + gold * gold_factor + gem * gem_factor
