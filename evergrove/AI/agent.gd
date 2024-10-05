# Controller for an individual instance of an AI agent
class_name Agent extends Node

# defaults
const DEFAULT_TYPE: ai_globals.AGENT_TYPE = ai_globals.AGENT_TYPE.DWARF
const DEFAULT_ENERGY: int = 100
const MAX_TASKS: int = 5

var type: ai_globals.AGENT_TYPE
var energy: int
var tasks: Array[Task]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ai_globals.AGENT_CREATED.emit(self)
	ai_globals.connect("PROCESS_TICK", _on_ai_tick)

static func create(type: ai_globals.AGENT_TYPE=DEFAULT_TYPE, energy: int = DEFAULT_ENERGY) -> Agent:
	var agent: Agent = Agent.new()
	agent.type = type
	agent.energy = energy
	return agent

# true if task assignment was successful
func assign_task(task: Task) -> bool:
	if tasks.size() < MAX_TASKS:
		tasks.append(task)
		return true
	else:
		return false

# TODO: implement "on tick" to do work
func _on_ai_tick():
	print(str(self.name) + " received AI tick event")
	if energy > 0:
		energy -= 1
	print(str(self.name) + " energy is now " + str(energy))
