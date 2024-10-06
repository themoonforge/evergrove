# Global AI controller layer between the player/game and individual agents
class_name Hivemind extends Node

var task_queue: Array[Task]
var agents:Array[Agent]
var taskless_agents:Array[Agent]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# subscribe to events
	ai_globals.connect("AGENT_CREATED", _on_agent_created)
	ai_globals.connect("AGENT_WITHOUT_TASK", _on_agent_without_task)
	ai_globals.connect("AGENT_NO_LONGER_TASKLESS", _remove_taskless_agent)
	add_child(AI_Timer.new())
	ai_globals.hivemind = self
	print("AI hivemind ready")

func _on_agent_created(agent: Agent):
	print("Registered agent " + str(agent.name) + " at hivemind")
	agents.append(agent)
	# debug: random movement task without layer change
	task_queue.append(Task.create(ai_globals.TASK_TYPE.MOVE_TO,"Move to random position", 0, Vector3(randf_range(-10,10),randf_range(-10,10), 0)))
	print("Added random move task to hivemind queue")

# TODO: create registry of unemployed agents
# TODO: create signal and slot for deregistering taskless agents, so they can remove their entry if e.g. they go to bed or do another personal needs task instead
func _on_agent_without_task(agent:Agent):
	if not task_queue.is_empty():
		var task:Task = task_queue.pop_front()
		if transfer_task_to_agent(task, agent):
			print("Hivemind transferred task to agent "+str(agent))
		else:
			print("Hivemind failed to transfer task to agent "+str(agent))
			task_queue.push_front(task)
	taskless_agents.append(agent)

func _remove_taskless_agent(agent:Agent):
	assert(agent in taskless_agents, "State mismatch. Agent  not found in taskless array.")
	taskless_agents.erase(agent)
	print("Removed "+str(agent)+" from taskless registry")

func transfer_task_to_agent(task: Task, agent: Agent) -> bool:
	if not agent.assign_task(task):
		print("Can't transfert task " + str(task.name) + " to agent " + str(agent.name) + ". Task not accepted by agent.")
		return false
	return true

func add_task(task:Task, important:bool=false):
	if important:
		task_queue.push_front(task)
		print("Hivemind added priority task "+str(task))
	else:
		task_queue.push_back(task)
		print("Hivemind added task "+str(task))
	
func get_agent_without_task() -> Agent:
	if not taskless_agents.is_empty():
		# TODO: search for closest agent
		return taskless_agents.front()
	return null

# TODO: management of global AI objects
