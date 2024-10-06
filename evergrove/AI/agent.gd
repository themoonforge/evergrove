# Controller for an individual instance of an AI agent
class_name Agent extends Node

# defaults
const DEFAULT_TYPE: ai_globals.AGENT_TYPE = ai_globals.AGENT_TYPE.DWARF
const DEFAULT_ENERGY: int = 100
const MAX_TASKS: int = 5

var type: ai_globals.AGENT_TYPE
var energy: int
var tasks: Array[Task]
var working_on_task:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ai_globals.connect("PROCESS_TICK", _on_ai_tick)
	ai_globals.AGENT_CREATED.emit(self)
	

static func create(type: ai_globals.AGENT_TYPE=DEFAULT_TYPE, energy: int = DEFAULT_ENERGY) -> Agent:
	var agent: Agent = Agent.new()
	agent.type = type
	agent.energy = energy
	return agent

# true if task assignment was successful
func assign_task(task: Task) -> bool:
	if tasks.size() < MAX_TASKS:
		tasks.append(task)
		print("Agent "+str(self)+" received task from hivemind")
		return true
	else:
		print("Agent "+str(self)+" rejected task: max task limit reached")
		return false

func _on_ai_tick():
	print(str(self.name) + " received AI tick event")
	if energy > 0:
		energy -= 1
	print(str(self.name) + " energy is now " + str(energy))
	
	# get task if agent queue is empty
	if tasks.is_empty():
		print("asking for work")
		ai_globals.AGENT_WITHOUT_TASK.emit(self)
		return
	
	# continue working on task
	if working_on_task:
		print("still working")
		#return
	
	# start new task
	match tasks.front().type:
		ai_globals.TASK_TYPE.MOVE_TO:
			print("match move to")
			if Vector3(self.get_parent().current_position.x, self.get_parent().current_position.y, self.get_parent().current_level).distance_to(tasks.front().location) > 1.0:
				print("call walk_to")
				self.get_parent().walk_to(Vector2(tasks.front().location.x, tasks.front().location.y), tasks.front().location.z)
				print("Agent "+str(self)+" moving to task location "+str(tasks.front().location))
				working_on_task = true
			else:
				print("pop agent task")
				tasks.pop_front()
				print("Agent "+str(self)+" reached task location")
				working_on_task = false
	
	
