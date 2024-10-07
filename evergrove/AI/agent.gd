# Controller for an individual instance of an AI agent
class_name Agent extends Node

const Utils = preload("res://Utils.gd")

# defaults
const DEFAULT_TYPE: ai_globals.AGENT_TYPE = ai_globals.AGENT_TYPE.DWARF
# also abused as max energy level for the moment
const DEFAULT_ENERGY: int = 100
const DEFAULT_FOOD: int = 100
const DEFAULT_BEER: int = 100
const MAX_TASKS: int = 5
const MIN_ENERGY_RECHARGE_PER_TICK:float=10
const MAX_ENERGY_RECHARGE_PER_TICK:float=20
const MIN_FOOD_RECHARGE_PER_TICK:float=10
const MAX_FOOD_RECHARGE_PER_TICK:float=20
const MIN_BEER_RECHARGE_PER_TICK:float=10
const MAX_BEER_RECHARGE_PER_TICK:float=20

const MIN_ENERGY_CONSUMTION_PER_TICK:float=0.1
const MAX_ENERGY_CONSUMTION_PER_TICK:float=1.5
const MIN_FOOD_CONSUMTION_PER_TICK:float=0.1
const MAX_FOOD_CONSUMTION_PER_TICK:float=1.5
const MIN_BEER_CONSUMTION_PER_TICK:float=0.1
const MAX_BEER_CONSUMTION_PER_TICK:float=1.5

const MINING_CONSUMTION_FACTOR:float=1.5
const SWIMMING_CONSUMTION_FACTOR:float=1.5
const BUILDING_CONSUMTION_FACTOR:float=1.5

const ENERGY_TRASHOLD:float=30
const FOOD_TRASHOLD:float=30
const BEER_TRASHOLD:float=30

var type: ai_globals.AGENT_TYPE
var energy: float
var food: float
var beer: float
var tasks: Array[Task]
var working_on_task:bool = false
var accepting_tasks:bool = true
var registered_as_taskless:bool = false
var recharge_energy_queued:bool = false
var recharge_food_queued:bool = false
var recharge_beer_queued:bool = false
var zero_energy_mode:bool = false
var zero_food_mode:bool = false
var zero_beer_mode:bool = false

var starving_mode: bool = false

var dwarf: Dwarf

func set_recharge_energy_queued(value:bool) -> void:
	recharge_energy_queued = value
	eval_accepting_tasks()

func set_recharge_food_queued(value:bool) -> void:
	recharge_food_queued = value
	eval_accepting_tasks()

func set_recharge_beer_queued(value:bool) -> void:
	recharge_beer_queued = value
	eval_accepting_tasks()
	
func eval_accepting_tasks() -> void:
	accepting_tasks = !(recharge_energy_queued || recharge_food_queued || recharge_beer_queued || starving_mode || tasks.size() >= MAX_TASKS)

func set_zero_energy_mode(value:bool) -> void:
	zero_energy_mode = value
	eval_starving_mode()
	
func set_zero_beer_mode(value:bool) -> void:
	zero_beer_mode = value
	eval_starving_mode()
	
func set_zero_food_mode(value:bool) -> void:
	zero_food_mode = value
	eval_starving_mode()

func eval_starving_mode() -> void:
	var new_starving_mode = zero_beer_mode || zero_energy_mode || zero_food_mode
	if (new_starving_mode && !starving_mode):
		# puck back all task if we enter starving mode
		push_back_all_task()

	starving_mode = new_starving_mode
	eval_accepting_tasks()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dwarf = self.get_parent()
	food = DEFAULT_FOOD
	energy = DEFAULT_ENERGY
	beer = DEFAULT_BEER
	recharge_energy_queued = false
	recharge_food_queued = false
	recharge_beer_queued = false
	eval_starving_mode()
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
		#print("Agent %s currently not accepting tasks" % [self.name])
		return false
	
	add_task_back(task)
	
	#print("Agent %s received task from hivemind" % [self.name])
	return true

func push_back_last_task() -> void:
	if tasks.size() >= MAX_TASKS:
		var size = tasks.size()	- 1
		for i in range(size, -1):
			var task = tasks[i]
			if task.is_interruptable():
				ai_globals.hivemind.add_task(task)
				tasks.remove_at(i)
				return

func push_back_all_task() -> void:
		var size = tasks.size()
		var removed = 0
		for i in range(0, size):
			var task = tasks[i - removed]
			if task.is_interruptable():
				ai_globals.hivemind.add_task(task)
				tasks.remove_at(i - removed)

func add_task_back(new_task: Task) -> void:
	push_back_last_task()
	
	if registered_as_taskless:
			ai_globals.AGENT_NO_LONGER_TASKLESS.emit(self)
			registered_as_taskless = false

	tasks.append(new_task)

func add_task_front(new_task: Task) -> void:
	push_back_last_task()
	
	if registered_as_taskless:
			ai_globals.AGENT_NO_LONGER_TASKLESS.emit(self)
			registered_as_taskless = false

	if tasks.size() == 0:
		tasks.append(new_task)
		return

	for i in range(tasks.size()):
		var task = tasks[i]
		if task.is_interruptable():
			#print("Agent %s inserting task at %d, %d" % [self.name, i, tasks.size()])
			tasks.insert(i, new_task)
			#print("Agent %s inserted task at %d, %d" % [self.name, i, tasks.size()])
			return
	
	#print("Agent %s inserted task at end %d" % [self.name, tasks.size() + 1])
	tasks.append(new_task)

func evaluate_consumtion() -> void:
	var energy_consumtion = randf_range(MIN_ENERGY_CONSUMTION_PER_TICK, MAX_ENERGY_CONSUMTION_PER_TICK)
	var food_consumtion = randf_range(MIN_FOOD_CONSUMTION_PER_TICK, MAX_FOOD_CONSUMTION_PER_TICK)
	var beer_consumtion = randf_range(MIN_BEER_CONSUMTION_PER_TICK, MAX_BEER_CONSUMTION_PER_TICK)

	match dwarf.behaviour:
		Utils.Behaviour.MINING:
			energy_consumtion *= MINING_CONSUMTION_FACTOR
			food_consumtion *= MINING_CONSUMTION_FACTOR
			beer_consumtion *= MINING_CONSUMTION_FACTOR
		Utils.Behaviour.SWIMMING:
			energy_consumtion *= SWIMMING_CONSUMTION_FACTOR
			food_consumtion *= SWIMMING_CONSUMTION_FACTOR
			beer_consumtion *= SWIMMING_CONSUMTION_FACTOR
		Utils.Behaviour.BUILDING:
			energy_consumtion *= BUILDING_CONSUMTION_FACTOR
			food_consumtion *= BUILDING_CONSUMTION_FACTOR
			beer_consumtion *= BUILDING_CONSUMTION_FACTOR

	var old_energy = energy
	var old_food = food
	var old_beer = beer

	energy = max(0, energy - energy_consumtion)
	food = max(0, food - food_consumtion)
	beer = max(0, beer - beer_consumtion)

	#print("Agent %s change enegery from %f to %f" % [self.name, old_energy, energy])
	#print("Agent %s change food from %f to %f" % [self.name, old_food, food])
	#print("Agent %s change beer from %f to %f" % [self.name, old_beer, beer])

	dwarf.update_bars(energy, food, beer)

#return Task or null
func generate_private_task(building_type: Utils.BuildingType):
	var location = ai_globals.Location.create_from_dwarf(dwarf)
	var target_location = ai_globals.hivemind.get_nearest_hub_location(building_type, location)
	if target_location.invalid:
		#print("Agent %s unable to create private task, target invalid (probably no hub exists)" % [self.name])
		return null
	match building_type:
		Utils.BuildingType.ENERGY:
			return Task.create(ai_globals.TASK_TYPE.SLEEP, "Move to nearest energy hub", 0, target_location)
		Utils.BuildingType.FOOD:
			return Task.create(ai_globals.TASK_TYPE.EAT, "Move to nearest food hub", 0, target_location)
		Utils.BuildingType.BEER:
			return Task.create(ai_globals.TASK_TYPE.DRINK, "Move to nearest beer hub", 0, target_location)

func evaluate_private_needs():
	#print("Agent %s private needs %s, %s, %s , %s, %s, %f, %f, %f" % [self.name, starving_mode, accepting_tasks, recharge_energy_queued, recharge_food_queued, recharge_beer_queued, energy, food, beer])
	if energy <= ENERGY_TRASHOLD && !recharge_energy_queued:
		var task = generate_private_task(Utils.BuildingType.ENERGY)
		if task:
			add_task_front(task)
			set_recharge_energy_queued(true)
			#print("%s has low energy, queueing energy task" % [self.name]) 
		#else:
			#print("%s unable to create energy task" % [self.name])
	if food <= FOOD_TRASHOLD && !recharge_food_queued:
		var task = generate_private_task(Utils.BuildingType.FOOD)
		if task:
			add_task_front(task)
			set_recharge_food_queued(true)
			#print("%s has low food, queueing food task" % [self.name]) 
		#else:
			#print("%s unable to create food task" % [self.name])
	if beer <= BEER_TRASHOLD && !recharge_beer_queued:
		var task = generate_private_task(Utils.BuildingType.BEER)
		if task:
			add_task_front(task)
			set_recharge_beer_queued(true)
			#print("%s has low beer, queueing beer task" % [self.name]) 
		#else:
			#print("%s unable to create beer task" % [self.name])

func evaluate_zero_modes():
	set_zero_energy_mode(energy == 0)
	set_zero_food_mode(food == 0)
	set_zero_beer_mode(beer == 0)

# return true if task is finished
func handle_task_end(task: Task) -> bool:
	#if !is_on_position(dwarf, task):
		#print("woops not on possition -> debug needed")
	if task.waiting_time <= 0:
		if task.has_callback:
			task.callback.call(dwarf)
		tasks.pop_front()
		working_on_task = false
		#print("Agent %s finished task" % [self.name])
		return true
	elif !task.waiting_running: 
		task.waiting_running = true
		task.waining_callback.call(dwarf)
	else:
		task.waiting_time -= 1
	return false

func run_task(task: Task) -> void:
	match task.type:
		ai_globals.TASK_TYPE.MOVE_TO:
			#print("Agent %s working on MOVE %s" % [self.name, working_on_task])
			if !working_on_task:
				walk_to(dwarf, task)
			else:
				if is_finished_walking(dwarf, task):
					if handle_task_end(task):
						eval_accepting_tasks()
				#else:
					#print("Agent %s still on task" % [self.name])
		ai_globals.TASK_TYPE.SLEEP:
			#print("Agent %s working on SLEEP %s" % [self.name, working_on_task])
			if !working_on_task:
				walk_to(dwarf, task)
			else: 
				if is_finished_walking(dwarf, task):
					dwarf.set_sleeping()
					var recharge = randf_range(MIN_ENERGY_RECHARGE_PER_TICK, MAX_ENERGY_RECHARGE_PER_TICK)
					energy = min(DEFAULT_ENERGY, energy + recharge)
					if energy >= DEFAULT_ENERGY:
						if handle_task_end(task):
							dwarf.set_normal()
							set_recharge_energy_queued(false)
							set_zero_energy_mode(false)
		ai_globals.TASK_TYPE.EAT:
			#print("Agent %s working on EAT %s" % [self.name, working_on_task])
			if !working_on_task:
				walk_to(dwarf, task)
			else: 
				if is_finished_walking(dwarf, task):
					dwarf.set_eating()
					var recharge = randf_range(MIN_FOOD_RECHARGE_PER_TICK, MAX_FOOD_RECHARGE_PER_TICK)
					food = min(DEFAULT_FOOD, food + recharge)
					if food >= DEFAULT_FOOD:
						if handle_task_end(task):
							dwarf.set_normal()
							set_recharge_food_queued(false)
							set_zero_food_mode(false)
		ai_globals.TASK_TYPE.DRINK:
			#print("Agent %s working on DRINK %s" % [self.name, working_on_task])
			if !working_on_task:
				walk_to(dwarf, task)
			else: 
				if is_finished_walking(dwarf, task):
					dwarf.set_drinking()
					var recharge = randf_range(MIN_BEER_RECHARGE_PER_TICK, MAX_BEER_RECHARGE_PER_TICK)
					beer = min(DEFAULT_BEER, beer + recharge)
					if beer >= DEFAULT_BEER:
						if handle_task_end(task):
							dwarf.set_normal()
							set_recharge_beer_queued(false)
							set_zero_beer_mode(false)

func _on_ai_tick():
	#print("Agent %s processing tick" % [self.name])
	evaluate_consumtion()
	evaluate_private_needs()
	evaluate_zero_modes()
	
	# get task if agent queue is empty
	if tasks.is_empty():
		#print("Agent "+str(self)+" task queue empty")
		ai_globals.AGENT_WITHOUT_TASK.emit(self) # check if this is a good idea
		registered_as_taskless = true
		return
	
	var task: Task = tasks.front()
	run_task(task)

func is_on_position(dwarf: Dwarf, task: Task) -> bool:
	return dwarf.current_level == task.location.level && task.location.coordinates.distance_to(dwarf.current_position) < 0.5

func walk_to(dwarf: Dwarf, task: Task) -> void:
	var movement_target:Vector3i = dwarf.walk_to(task.location.coordinates, task.location.level)
	task.location.coordinates.x = movement_target.x
	task.location.coordinates.y = movement_target.y
	task.location.level = movement_target.z
	#print("Agent %s moving to task location %v, %d" % [self.name, task.location.coordinates, task.location.level])
	working_on_task = true
	
func is_finished_walking(dwarf: Dwarf, task: Task) -> bool:
	if (dwarf.behaviour == Utils.Behaviour.IDLE || dwarf.walking_path.size() == 0):
		if (is_on_position(dwarf, task)):
			return true
		else:
			walk_to(dwarf, task)
			return false
	return false
