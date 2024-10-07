# Global AI controller layer between the player/game and individual agents
class_name Hivemind extends Node

@onready var world: World = $"/root/Game/World"
const Utils = preload("../Utils.gd")

var task_queue: Array[Task]
var agents: Array[Agent]
var taskless_agents: Array[Agent]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# subscribe to events
	ai_globals.connect("AGENT_CREATED", _on_agent_created)
	ai_globals.connect("AGENT_DIE", _on_agent_died)
	ai_globals.connect("AGENT_WITHOUT_TASK", _on_agent_without_task)
	ai_globals.connect("AGENT_NO_LONGER_TASKLESS", _remove_taskless_agent)
	add_child(AI_Timer.new())
	ai_globals.hivemind = self
	print("AI hivemind ready")

func _on_agent_created(agent: Agent):
	print("Registered agent " + str(agent.name) + " at hivemind")
	agents.append(agent)
	# debug: random movement task without layer change
	#task_queue.append(Task.create(ai_globals.TASK_TYPE.MOVE_TO,"Move to random position", 0, ai_globals.Location.create(Vector2i(randi_range(-10,10),randi_range(-10,10)), 0)))
	#print("Added random move task to hivemind queue")

func _on_agent_died(agent: Agent):
	print("Deregistered agent " + str(agent.name) + " at hivemind")
	agents.erase(agent)

# TODO: create registry of unemployed agents
# TODO: create signal and slot for deregistering taskless agents, so they can remove their entry if e.g. they go to bed or do another personal needs task instead
func _on_agent_without_task(agent: Agent):
	if not task_queue.is_empty():
		var task: Task = get_nearest_task_to_agent(agent)
		if transfer_task_to_agent(task, agent):
			print("Hivemind transferred task to agent " + str(agent))
			task_queue.erase(task)
		else:
			print("Hivemind failed to transfer task to agent " + str(agent))
	taskless_agents.append(agent)

func _remove_taskless_agent(agent: Agent):
	assert(agent in taskless_agents, "State mismatch. Agent  not found in taskless array.")
	taskless_agents.erase(agent)
	print("Removed " + str(agent) + " from taskless registry")

func transfer_task_to_agent(task: Task, agent: Agent) -> bool:
	if not agent.assign_task(task):
		print("Can't transfert task " + str(task.name) + " to agent " + str(agent.name) + ". Task not accepted by agent.")
		return false
	return true

func add_task(task: Task, important: bool = false):
	if important:
		task_queue.push_front(task)
		print("Hivemind added priority task " + str(task))
		transfer_task_to_agent(task, get_agent_without_task(task))
	else:
		task_queue.push_back(task)
		print("Hivemind added task " + str(task))

func get_nearest_task_to_agent(agent: Agent) -> Task:
	if not task_queue.is_empty():
		var smallest_distance: float = task_queue.front().location.coordinates.distance_to(agent.dwarf.current_position)
		var nearest_task: Task = task_queue.front()
		for task in task_queue:
			if task == task_queue.front():
				continue
			var distance: float = task.location.coordinates.distance_to(agent.dwarf.current_position)
			if distance < smallest_distance:
				smallest_distance = distance
				nearest_task = task
		return nearest_task
	return null

func get_agent_without_task(task: Task) -> Agent:
	if not taskless_agents.is_empty():
		var smallest_distance: float = taskless_agents.front().dwarf.current_position.distance_to(task.location.coordinates)
		var nearest_agent: Agent = taskless_agents.front()
		for agent in taskless_agents:
			if agent == taskless_agents.front():
				continue
			var distance: float = agent.dwarf.current_position.distance_to(task.location.coordinates)
			if distance < smallest_distance:
				smallest_distance = distance
				nearest_agent = agent
		return nearest_agent
	return null

func get_nearest_hub_location(building_type: Utils.BuildingType, agent_location: ai_globals.Location) -> ai_globals.Location:
	var vec3_or_null = world.get_nearest_building_location_retry(building_type, agent_location.coordinates, agent_location.level)
	
	# return agent's own location if no hub was found as movement target
	if vec3_or_null == null:
		print("No hub found, returning agent's own location")
		return ai_globals.Location.create(Vector2i.ZERO, 0, true)
		
	var vec3: Vector3i = vec3_or_null
	return ai_globals.Location.create(Vector2i(vec3.x, vec3.y), vec3.z)
