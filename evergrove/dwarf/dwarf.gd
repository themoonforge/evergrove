extends Node2D

class_name Dwarf

@export var current_dungeon_layer: DungeonLayer

@onready var game_state: GameState = $"/root/Game/GameState"
@onready var world: World = $"/root/Game/World"

@export var walking_speed = 75.0
@export var walking_direction = WalkingDirection.FRONT
@export var walking = false
@export var walking_path: PackedVector3Array = []
@export var current_level = 0
@export var current_position: Vector2i = Vector2i(0, 0)
@export var view_range: int = 3

enum WalkingDirection {
	FRONT,
	BACK,
	LEFT,
	RIGHT
}

func set_current_position(my_position: Vector2i, level: int, force: bool = false) -> void:
	if !force && current_position == my_position && current_level == level:
		return
	current_position = my_position
	current_level = level
	current_dungeon_layer.clear_fow(my_position, view_range)

func _ready():
	# TODO retrieve walking direction and call play on animated sprite
	# this is just an example how to call animations
	var animated_sprite = self.get_child(1)
	animated_sprite.play("walk_front")
	# instantiate AI controller
	add_child(Agent.create())
	game_state.selected_dwarf = self
		

func set_walking_direction(direction: WalkingDirection) -> void:
	if walking_direction == direction:
		return
	walking_direction = direction
	# TODO call play on animated sprite
	# this is just an example how to call animations
	var animated_sprite = self.get_child(1)
	match walking_direction:
		WalkingDirection.FRONT:
			animated_sprite.play("walk_front")
		WalkingDirection.BACK:
			animated_sprite.play("walk_back")
		WalkingDirection.LEFT:
			animated_sprite.play("walk_left")
		WalkingDirection.RIGHT:
			animated_sprite.play("walk_right")

func _process(delta):
	if walking_path.size() > 0:
		walking = true
		var target: Vector3i = walking_path[0]
		if (target.z != current_level):
			current_dungeon_layer.dwarf_container.remove_child(self)
			set_current_position(current_position, target.z)
			current_level = target.z
			current_dungeon_layer = world.tile_maps[current_level]
			current_dungeon_layer.dwarf_container.add_child(self)
			walking_path.remove_at(0)
			if walking_path.size() == 0:
				walking = false
				var animated_sprite = self.get_child(1)
				animated_sprite.stop()
				animated_sprite.play("default")
			return
		var target2D = world.visible_tile_map.map_to_local(Vector2(target.x, target.y))

		var direction = (target2D - position).normalized()
		var velocity = direction * walking_speed * delta
		
		if direction.x > 0:
			set_walking_direction(WalkingDirection.RIGHT)
		elif direction.x < 0:
			set_walking_direction(WalkingDirection.LEFT)
		elif direction.y > 0:
			set_walking_direction(WalkingDirection.FRONT)
		elif direction.y < 0:
			set_walking_direction(WalkingDirection.BACK)
		
		var offset = Vector2i(0, 0)
		match walking_direction:
			WalkingDirection.FRONT:
				offset.y = 1
			WalkingDirection.BACK:
				offset.y = -1
			WalkingDirection.LEFT:
				offset.x = -1
			WalkingDirection.RIGHT:
				offset.x = 1

		var next_position = current_position + offset

		var data = world.get_tile_data(next_position, target.z)

		var walking_speed_factor: float = data.get_custom_data("walking_speed_factor")
		
		velocity *= walking_speed_factor

		position += velocity
		if (position - target2D).length() < 1.0:
			position = target2D
			set_current_position(Vector2(target.x, target.y), current_level)
		
			walking_path.remove_at(0)

			var data_now = world.get_tile_data(current_position, target.z)
			var walkable: bool = data_now.get_custom_data("walkable")
			if !walkable:
				world.mine_tile(current_position, current_level)
		
			if walking_path.size() == 0:
				walking = false
				var animated_sprite = self.get_child(1)
				animated_sprite.stop()
				# TODO set walking direction
				# this is just an example how to call animations
				animated_sprite.play("default")

func walk_to(target: Vector2, level: int) -> void:
	var current_key = world.get_unique_id(current_position, current_level)
	var target_key = world.get_unique_id(target, level)
	var path = world.astar.get_point_path(current_key, target_key)
	walking_path = path
