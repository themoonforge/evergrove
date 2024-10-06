class_name Task extends Node

var type:ai_globals.TASK_TYPE
var description:String
var energy_cost: int
var location:ai_globals.Location


# factory pattern instead of overloading _init method
static func create(task_type:ai_globals.TASK_TYPE, description:String, energy_cost: int=0, location:ai_globals.Location=ai_globals.Location.create(Vector2i.ZERO, 0)) -> Task:
	var task = Task.new()
	task.type=task_type
	task.description=description
	task.energy_cost = energy_cost
	task.location=location
	return task
