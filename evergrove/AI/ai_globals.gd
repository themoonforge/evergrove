extends Node

var hivemind:Hivemind

# list of available AI agents with different behavior
enum AGENT_TYPE {
	DWARF
}

signal AGENT_CREATED(agent: Agent)
signal PROCESS_TICK()
signal AGENT_WITHOUT_TASK(agent:Agent)
signal AGENT_NO_LONGER_TASKLESS(agent:Agent)
#signal ENERGY_HUB_SPAWNED(energy_hub:EnergyHub)

enum TASK_TYPE {
	MOVE_TO,
	MINE,
	EAT,
	SLEEP
}

class Location:
	var layer:int
	var coordinates:Vector2i
	static func create(coordinates:Vector2i, layer:int) -> Location:
		var instance = Location.new()
		instance.coordinates = coordinates
		instance.layer - layer
		return instance
