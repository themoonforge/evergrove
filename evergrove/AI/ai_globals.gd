extends Node

# list of available AI agents with different behavior
enum AGENT_TYPE {
	DWARF
}

signal AGENT_CREATED(agent: Agent)
signal PROCESS_TICK()
signal AGENT_WITHOUT_TASK(agent:Agent)

enum TASK_TYPE {
	MOVE_TO,
	MINE,
	EAT,
	SLEEP
}
