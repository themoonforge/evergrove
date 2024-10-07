# Controller for an individual instance of an AI agent
class_name Agent extends Node

const Utils = preload("res://Utils.gd")

# defaults
const DEFAULT_TYPE: ai_globals.AGENT_TYPE = ai_globals.AGENT_TYPE.DWARF
# also abused as max energy level for the moment
const DEFAULT_ENERGY: int = 100
const MAX_TASKS: int = 5
const ENERGY_RECHARGE_PER_TICK:int=5

var type: ai_globals.AGENT_TYPE
var energy: int
var tasks: Array[Task]
var working_on_task:bool = false
var accepting_tasks:bool = true
var registered_as_taskless:bool = false
var recharge_energy_queued:bool = false
var zero_energy_mode:bool = false

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
	#print(str(self.name) + " received AI tick event")
	if energy > 0:
		energy -= 1
	#print(str(self.name) + " energy is now " + str(energy))
	if energy <= 30 and not recharge_energy_queued:
		print(str(self.name) + " has low energy, queueing sleep task")
		var task:Task = Task.create(ai_globals.TASK_TYPE.SLEEP, "Sleep to recharge energy", 0, ai_globals.hivemind.get_nearest_energy_hub_location(ai_globals.Location.create(Vector2i(self.get_parent().current_position.x,self.get_parent().current_position.y), self.get_parent().current_level)))
		# TODO: check if task queue is full, if yes send last task back to hivemind and add new sleep task
		if tasks.size() == MAX_TASKS:
			ai_globals.hivemind.add_task(tasks.pop_back())
		self.tasks.append(task)
		recharge_energy_queued = true
		accepting_tasks = false
		if registered_as_taskless:
			ai_globals.AGENT_NO_LONGER_TASKLESS.emit(self)
			registered_as_taskless = false
	if energy == 0 and not zero_energy_mode:
		print(str(self.name) + " energy zero, aborting tasks")
		zero_energy_mode = true
		accepting_tasks = false
		working_on_task = false
		# hand back unfinished tasks to hivemind
		while not tasks.is_empty():
			if tasks.front().type == ai_globals.TASK_TYPE.SLEEP:
				break
			ai_globals.hivemind.add_task(tasks.pop_front())
		# add sleep task in case we somehow skipped the low energy threshold trigger which normally creates it
		if not recharge_energy_queued:
			self.tasks.append(Task.create(ai_globals.TASK_TYPE.SLEEP, "Sleep to recharge energy", 0, ai_globals.hivemind.get_nearest_energy_hub_location(ai_globals.Location.create(Vector2i(self.get_parent().current_position.x,self.get_parent().current_position.y), self.get_parent().current_level))))
			recharge_energy_queued = true
			if registered_as_taskless:
				ai_globals.AGENT_NO_LONGER_TASKLESS.emit(self)
				registered_as_taskless = false
		# TODO: reduce happiness
	
	# get task if agent queue is empty
	if tasks.is_empty():
		#print("Agent "+str(self)+" task queue empty")
		ai_globals.AGENT_WITHOUT_TASK.emit(self)
		registered_as_taskless = true
		return
	
	var task: Task = tasks.front()
	var dwarf: Dwarf = self.get_parent()

	match task.type:
		ai_globals.TASK_TYPE.MOVE_TO:
			# TODO: do not use Vec3 distance or +- 1 layer might falsely trigger target reached
			if !working_on_task: # && !is_on_position(dwarf, task.location.coordinates, task.location.layer):
				walk_to(dwarf, task)
			else:
				if is_finished_walking(dwarf):
					if !is_on_position(dwarf, task):
						print("woops not on possition -> debug needed")
					if task.waiting_time <= 0:
						if task.has_callback:
							task.callback.call(dwarf)
						tasks.pop_front()
						print("Agent "+str(self)+" reached task location")
						working_on_task = false
						accepting_tasks = true
					elif !task.running: 
						task.running = true
						task.waining_callback.call(dwarf)
					else:
						task.waiting_time -= 1
				else:
					print("Agent "+str(self)+" still on task")
		ai_globals.TASK_TYPE.SLEEP:
			if task.location.invalid:
				print("Agent "+str(self)+" unable to do sleep task, target invalid (probably no energy hub exists)")
				return
			if !working_on_task: # && !is_on_position(dwarf, task.location.coordinates, task.location.layer):
				walk_to(dwarf, task)
			else: 
				if is_finished_walking(dwarf):
					dwarf.set_sleeping()
					if energy + ENERGY_RECHARGE_PER_TICK >= DEFAULT_ENERGY:
						energy = DEFAULT_ENERGY
						if task.has_callback:
							task.callback.call(dwarf)
						tasks.pop_front()
						recharge_energy_queued = false
						working_on_task = false
						accepting_tasks = true
						zero_energy_mode = false
						dwarf.set_normal()
					else:
						energy += ENERGY_RECHARGE_PER_TICK

func is_on_position(dwarf: Dwarf, task: Task) -> bool:
	return dwarf.current_level == task.location.layer && task.location.coordinates.distance_to(dwarf.current_position) < 1

func walk_to(dwarf: Dwarf, task: Task) -> void:
	var movement_target:Vector3i = dwarf.walk_to(task.location.coordinates, task.location.layer)
	task.location.coordinates.x = movement_target.x
	task.location.coordinates.y = movement_target.y
	task.location.layer = movement_target.z
	print("Agent "+str(self)+" moving to task location "+str(task.location))
	working_on_task = true
	
func is_finished_walking(dwarf: Dwarf) -> bool:
	return dwarf.behaviour == Utils.Behaviour.IDLE || dwarf.walking_path.size() == 0
