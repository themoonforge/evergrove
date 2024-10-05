extends Node2D

class_name Dwarf

var current_dungeon_layer

@onready var game_state: GameState = $"/root/Game/GameState"
@onready var world: World = $"/root/Game/World"

@export var walking_speed = 10.0
@export var walking_direction = WalkingDirection.FRONT
@export var walking = false
@export var walking_path: PackedVector3Array = []
@export var current_level = 0
@export var current_position: Vector2 = Vector2(0, 0)

enum WalkingDirection {
	FRONT,
	BACK,
	LEFT,
	RIGHT
}

func _ready():
	# TODO retrieve walking direction and call play on animated sprite
	# this is just an example how to call animations
	var animated_sprite = self.get_child(1)
	animated_sprite.play("walk_front")
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
		var target: Vector3i = walking_path[0]
		if (target.z != current_level):
			# TODO implement stairs
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

		position += velocity
		if (position - target2D).length() < 1.0:
			position = target2D
			current_position = Vector2(target.x, target.y)
			walking_path.remove_at(0)
			if walking_path.size() == 0:
				walking = false
				var animated_sprite = self.get_child(1)
				animated_sprite.stop()
				# TODO set walking direction
				# this is just an example how to call animations
				animated_sprite.play("default")
