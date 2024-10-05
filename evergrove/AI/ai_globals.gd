class_name AI_GLOBALS

# list of available AI agents with different behavior
enum AGENT_TYPE {
	DWARF
}

signal AGENT_CREATED(agent: Agent)
signal PROCESS_TICK()
