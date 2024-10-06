extends Node2D

class_name Hub

const Utils = preload("../Utils.gd")

@onready var beer: AnimatedSprite2D = $"./Beer"
@onready var energy: AnimatedSprite2D = $"./Energy"
@onready var food: AnimatedSprite2D = $"./Food"

@export var type: Utils.BuildingType

@export var tiles: Dictionary

func init(my_type: Utils.BuildingType, my_tiles: Dictionary = {}): 
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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
