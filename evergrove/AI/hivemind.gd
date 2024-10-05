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
	add_child(AI_Timer.new())
	print("Created AI hivemind")
	add_child(Agent.create())

func _on_agent_created(agent: Agent):
	print("Registered agent " + str(agent.name) + " at hivemind")
	agents.append(agent)

func transfer_task_to_agent(task: Task, agent: Agent) -> bool:
	# task unknown to hivemind
	if not task in task_queue:
		print("Can't transfert task " + str(task.name) + " to agent " + str(agent.name) + ". Task unknown to hivemind.")
		return false
	# agent not accepting task
	if not agent.assign_task(task):
		print("Can't transfert task " + str(task.name) + " to agent " + str(agent.name) + ". Task not accepted by agent.")
		return false
	return true

# TODO: function to receive task from agent
func receive_task_from_agent():
	pass

# TODO: management of global AI objects
