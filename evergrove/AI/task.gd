class_name Task extends Node

var type:ai_globals.TASK_TYPE
var description:String
var energy_cost: int
var location:ai_globals.Location
var has_callback: bool
var callback: Callable
var waiting_time: int
var waining_callback: Callable
var running: bool = false

static var default_callback: Callable = func(dwarf):
	pass

# factory pattern instead of overloading _init method
static func create(task_type:ai_globals.TASK_TYPE, description:String, energy_cost: int=0, location:ai_globals.Location=ai_globals.Location.create(Vector2i.ZERO, 0), callback: Callable = default_callback, waiting_callback: Callable = default_callback, waiting_time = -1) -> Task:
	var task = Task.new()
	task.type=task_type
	task.description=description
	task.energy_cost = energy_cost
	task.location=location
	task.has_callback = callback != default_callback
	task.callback=callback
	task.waiting_time = waiting_time
	task.waining_callback = waiting_callback
	return task
