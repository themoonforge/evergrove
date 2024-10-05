class_name Task extends Node

var energy_cost: int

# TODO: use proper coordinates and probably wrap this into another container class to also include the map layer or use 3D coords
var location

# factory pattern instead of overloading _init method
static func create(energy_cost: int) -> Task:
    var task = Task.new()
    task.energy_cost = energy_cost
    return task
