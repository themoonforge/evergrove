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

@export var dwarfs = 0

@export var wealth = 0

@export var current_level = 0

@export var silver_factor = 1
@export var gold_factor = 10
@export var gem_factor = 100

@export var selected_dwarf: Dwarf

@export var wealth_spend: int = 0

# Setter methods
func _set_dirt(value: int) -> void:
	dirt = value
	gui.set_label_dirt(str(dirt))

func _set_stone(value: int) -> void:
	stone = value
	gui.set_label_stone(str(stone))

func _set_coal(value: int) -> void:
	coal = value

func _set_iron(value: int) -> void:
	iron = value
	gui.set_label_iron(str(iron))

func _set_copper(value: int) -> void:
	copper = value
	gui.set_label_copper(str(copper))

func _set_silver(value: int) -> void:
	silver = value
	_set_wealth(calc_wealth())

func _set_gold(value: int) -> void:
	gold = value
	_set_wealth(calc_wealth())

func _set_gem(value: int) -> void:
	gem = value
	_set_wealth(calc_wealth())

func _set_water(value: int) -> void:
	water = value
	gui.set_label_water(str(water))

func _set_micel(value: int) -> void:
	micel = value
	gui.set_label_micel(str(micel))

func _set_wealth(value: int) -> void:
	wealth = value
	gui.set_label_wealth(str(wealth))

func set_current_level(value: int) -> void:
	current_level = value
	gui.set_label_current_level(str(current_level))

func _set_dwarfs(value: int) -> void:
	dwarfs = value
	gui.set_label_dwarf(str(dwarfs))

# Increment and Decrement methods
func inc_dirt(amount: int) -> void:
	_set_dirt(dirt + amount)

func dec_dirt(amount: int) -> void:
	_set_dirt(dirt - amount)

func inc_stone(amount: int) -> void:
	_set_stone(stone + amount)

func dec_stone(amount: int) -> void:
	_set_stone(stone - amount)

func inc_coal(amount: int) -> void:
	_set_coal(coal + amount)

func dec_coal(amount: int) -> void:
	_set_coal(coal - amount)

func inc_iron(amount: int) -> void:
	_set_iron(iron + amount)

func dec_iron(amount: int) -> void:
	_set_iron(iron - amount)

func inc_copper(amount: int) -> void:
	_set_copper(copper + amount)

func dec_copper(amount: int) -> void:
	_set_copper(copper - amount)

func inc_silver(amount: int) -> void:
	_set_silver(silver + amount)

func inc_gold(amount: int) -> void:
	_set_gold(gold + amount)

func inc_gem(amount: int) -> void:
	_set_gem(gem + amount)

func dec_wealth(amount: int) -> void:
	_set_wealth(wealth - amount)

func inc_water(amount: int) -> void:
	_set_water(water + amount)

func dec_water(amount: int) -> void:
	_set_water(water - amount)

func inc_micel(amount: int) -> void:
	_set_micel(micel + amount)

func dec_micel(amount: int) -> void:
	_set_micel(micel - amount)

func inc_dwarfs(amount: int) -> void:
	_set_dwarfs(dwarfs + amount)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_set_coal(0)
	_set_copper(0)
	_set_dirt(0)
	_set_gem(0)
	_set_gold(0)
	_set_stone(0)
	_set_silver(0)
	_set_water(0)
	_set_micel(0)
	_set_iron(0)
	_set_dwarfs(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func calc_wealth() -> int:
	return silver * silver_factor + gold * gold_factor + gem * gem_factor - wealth_spend
