class_name Task extends Node

var type:ai_globals.TASK_TYPE
var description:String
var energy_cost: int
var location:Vector3


# factory pattern instead of overloading _init method
static func create(task_type:ai_globals.TASK_TYPE, description:String, energy_cost: int=0, location:Vector3=Vector3.ZERO) -> Task:
	var task = Task.new()
	task.type=task_type
	task.description=description
	task.energy_cost = energy_cost
	task.location=location
	return task
