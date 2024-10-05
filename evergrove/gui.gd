extends CanvasLayer

@onready var world = $/root/Game/World
@onready var factory = $/root/Game/Factory

@export var spawn_position:Vector2i



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_spawn_dwarf_button_pressed():
	var dungeon_layer_index = 0 # TODO use correct dungeon  layer
	var position = spawn_position # TODO use correct position
	
	var dungeon_layer = world.get_child(dungeon_layer_index)
	var dwarf_container = dungeon_layer.dwarf_container
	
	var dwarf = preload("res://dwarf/Dwarf.tscn").instantiate()
	dwarf_container.add_child(dwarf)
	dwarf.position = dungeon_layer.map_to_local(position) # TODO convert to map position
	dwarf.current_dungeon_layer = dungeon_layer

func _on_spawn_energy_hub_button_pressed():
	var dungeon_layer_index = 0 # TODO use correct dungeon  layer
	var position = spawn_position # TODO use correct position
	
	var dungeon_layer = world.get_child(dungeon_layer_index)
	var hub_container = dungeon_layer.hub_container
	
	var energy_hub = preload("res://hubs/EnergyHub.tscn").instantiate()
	hub_container.add_child(energy_hub)
	energy_hub.position = dungeon_layer.map_to_local(position) # TODO convert to map position
	#energy_hub.current_dungeon_layer = dungeon_layer
