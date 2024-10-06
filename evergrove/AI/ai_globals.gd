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

enum TASK_TYPE {
	MOVE_TO,
	MINE,
	EAT,
	SLEEP
}

class Location:
	var coordinates:Vector2i
	var layer:int
	var invalid:bool
	static func create(coordinates:Vector2i, layer:int, invalid:bool=false) -> Location:
		var instance = Location.new()
		instance.coordinates = coordinates
		instance.layer = layer
		instance.invalid = invalid
		return instance
