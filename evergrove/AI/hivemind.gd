# Global AI controller layer between the player/game and individual agents
class_name Hivemind extends Node

# task queue
var task_queue: Array = []

# agents in the game
var agents = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# subscribe to events
	ai_globals.connect("AGENT_CREATED", _on_agent_created)
	ai_globals.connect("AGENT_WITHOUT_TASK", _on_agent_without_task)
	add_child(AI_Timer.new())
	print("AI hivemind ready")

func _on_agent_created(agent: Agent):
	print("Registered agent " + str(agent.name) + " at hivemind")
	agents.append(agent)
	# debug: random movement task without layer change
	task_queue.append(Task.create(ai_globals.TASK_TYPE.MOVE_TO,"Move to random position", 0, Vector3(randf_range(-10,10),randf_range(-10,10), 0)))
	print("Added random move task to hivemind queue")

func _on_agent_without_task(agent:Agent):
	if not task_queue.is_empty():
		var task:Task = task_queue.pop_front()
		if transfer_task_to_agent(task, agent):
			print("Hivemind transferred task to agent "+str(agent))
		else:
			print("Hivemind failed to transfer task to agent "+str(agent))
			task_queue.push_front(task)

func transfer_task_to_agent(task: Task, agent: Agent) -> bool:
	if not agent.assign_task(task):
		print("Can't transfert task " + str(task.name) + " to agent " + str(agent.name) + ". Task not accepted by agent.")
		return false
	return true

# TODO: function to receive task from agent
func receive_task_from_agent():
	pass

func get_agent_without_task() -> Agent:
	for agent in agents:
		if agent.tasks.is_empty():
			return agent
	return null
# TODO: management of global AI objects
