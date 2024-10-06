class_name EnergyHub extends Node2D

var location:ai_globals.Location

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func register_with_hivemind():
	ai_globals.ENERGY_HUB_SPAWNED.emit(self)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
