# Controller for an individual instance of an AI agent
class_name Agent extends Node

# defaults
const DEFAULT_TYPE: ai_globals.AGENT_TYPE = ai_globals.AGENT_TYPE.DWARF
# also abused as max energy level for the moment
const DEFAULT_ENERGY: int = 100
const MAX_TASKS: int = 5

var type: ai_globals.AGENT_TYPE
var energy: int
var tasks: Array[Task]
var working_on_task:bool = false
var accepting_tasks:bool = true
var registered_as_taskless:bool = false
var recharge_energy_queued:bool = false

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
	if not accepting_tasks:
		print("Agent "+str(self)+" currently not accepting tasks")
		return false
	if tasks.size() == MAX_TASKS:
		print("Agent "+str(self)+" rejected task: task queue full")
		return false
	tasks.append(task)
	if registered_as_taskless:
		ai_globals.AGENT_NO_LONGER_TASKLESS.emit(self)
		registered_as_taskless = false
	print("Agent "+str(self)+" received task from hivemind")
	return true

func _on_ai_tick():
	print(str(self.name) + " received AI tick event")
	if energy > 0:
		energy -= 1
	print(str(self.name) + " energy is now " + str(energy))
	if energy <= 30 and not recharge_energy_queued:
		print(str(self.name) + " has low energy, queueing sleep task")
		# TODO: get closest free bed position from hivemind
		var task:Task = Task.create(ai_globals.TASK_TYPE.SLEEP, "Sleep to recharge energy", 0, Vector3.ZERO)
		# TODO: check if task queue is full, if yes send last task back to hivemind and add new sleep task
		if tasks.size() == MAX_TASKS:
			ai_globals.hivemind.add_task(tasks.pop_back())
		self.tasks.append(task)
		recharge_energy_queued = true
		if registered_as_taskless:
			ai_globals.AGENT_NO_LONGER_TASKLESS.emit(self)
			registered_as_taskless = false
	if energy == 0:
		print(str(self.name) + " energy zero, aborting tasks")
		accepting_tasks = false
		# hand back unfinished tasks to hivemind
		while not tasks.is_empty():
			if tasks.front().type == ai_globals.TASK_TYPE.SLEEP:
				break
			ai_globals.hivemind.add_task(tasks.pop_front())
		# add sleep task in case we somehow skipped the low energy threshold trigger which normally creates it
		if not recharge_energy_queued:
			self.tasks.append(Task.create(ai_globals.TASK_TYPE.SLEEP, "Sleep to recharge energy", 0, Vector3.ZERO))
			recharge_energy_queued = true
			if registered_as_taskless:
				ai_globals.AGENT_NO_LONGER_TASKLESS.emit(self)
				registered_as_taskless = false
		# TODO: reduce happiness
	
	# get task if agent queue is empty
	if tasks.is_empty():
		print("Agent "+str(self)+" task queue empty")
		ai_globals.AGENT_WITHOUT_TASK.emit(self)
		registered_as_taskless = true
		return
	
	match tasks.front().type:
		ai_globals.TASK_TYPE.MOVE_TO:
			print("Distance to target "+str(Vector3(self.get_parent().current_position.x, self.get_parent().current_position.y, self.get_parent().current_level).distance_to(tasks.front().location)))
			if Vector3(self.get_parent().current_position.x, self.get_parent().current_position.y, self.get_parent().current_level).distance_to(tasks.front().location) > 1.0:
				self.get_parent().walk_to(Vector2(tasks.front().location.x, tasks.front().location.y), tasks.front().location.z)
				print("Agent "+str(self)+" moving to task location "+str(tasks.front().location))
				working_on_task = true
			else:
				tasks.pop_front()
				print("Agent "+str(self)+" reached task location")
				working_on_task = false
		ai_globals.TASK_TYPE.SLEEP:
			if Vector3(self.get_parent().current_position.x, self.get_parent().current_position.y, self.get_parent().current_level).distance_to(tasks.front().location) > 1.0:
				self.get_parent().walk_to(Vector2(tasks.front().location.x, tasks.front().location.y), tasks.front().location.z)
				print("Agent "+str(self)+" moving to task location "+str(tasks.front().location))
				working_on_task = true
			else:
				tasks.pop_front()
				print("Agent "+str(self)+" reached task location")
				energy = DEFAULT_ENERGY
				recharge_energy_queued = false
				print("Agent "+str(self)+" instant sleep refilled energy")
				working_on_task = false
				accepting_tasks = true
