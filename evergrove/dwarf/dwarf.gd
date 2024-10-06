extends Node2D

class_name Dwarf

@export var current_dungeon_layer: DungeonLayer

@onready var character_animator: AnimatedSprite2D = $"./CharacterAnimator"
@onready var effect_animator: AnimatedSprite2D = $"./EffectAnimator"

@onready var game_state: GameState = $"/root/Game/GameState"
@onready var world: World = $"/root/Game/World"

@export var walking_speed: float = 75.0
@export var walking_direction: WalkingDirection = WalkingDirection.DEFAULT
@export var behaviour: Behaviour = Behaviour.IDLE
@export var walking_path: PackedVector3Array = []
@export var current_level: int = 0
@export var current_position: Vector2i = Vector2i(0, 0)
@export var view_range: int = 3

const idle_animation = "default"
const sleeping_animation = idle_animation
const eating_animation = idle_animation

const walking_front_animation = "walk_front"
const walking_back_animation = "walk_back"
const walking_left_animation = "walk_left"
const walking_right_animation = "walk_right"
const walking_default_animation = "default"

const swiming_front_animation = walking_front_animation
const swiming_back_animation = walking_back_animation
const swiming_left_animation = walking_left_animation
const swiming_right_animation = walking_right_animation
const swiming_default_animation = walking_default_animation

const mining_front_animation = walking_front_animation
const mining_back_animation = walking_back_animation
const mining_left_animation = walking_left_animation
const mining_right_animation = walking_right_animation
const mining_default_animation = walking_default_animation

const mining_effect = "mining_effect"
const eating_effect = "eating_effect"
const sleeping_effect = "sleeping_effect"

enum WalkingDirection {
	FRONT,
	BACK,
	LEFT,
	RIGHT,
	DEFAULT
}

enum Behaviour {
	IDLE,
	WALKING,
	SWIMMING,
	MINING,
	SLEEPING,
	EATING,
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
	# instantiate AI controller
	add_child(Agent.create())
	game_state.selected_dwarf = self
	game_state.inc_dwarfs(1)
	set_animation(Behaviour.IDLE, WalkingDirection.DEFAULT)

func play_animation(animator: AnimatedSprite2D, animation: String) -> void:
	if !animator.is_playing() || animator.animation != animation || !animator.visible:
		animator.visible = true
		animator.play(animation)

func stop_animation(animator: AnimatedSprite2D) -> void:
	if animator.is_playing() || animator.visible:
		animator.stop()
		animator.visible = false

func set_animation(my_behaviour: Behaviour, my_walking_direction: WalkingDirection) -> void:
	if behaviour == my_behaviour && walking_direction == my_walking_direction:
		return	

	behaviour = my_behaviour
	walking_direction = my_walking_direction
	
	match behaviour:
		Behaviour.IDLE:
			play_animation(character_animator, idle_animation)
			stop_animation(effect_animator)
		Behaviour.WALKING:
			stop_animation(effect_animator)
			match walking_direction:
				WalkingDirection.FRONT:
					play_animation(character_animator, walking_front_animation)
				WalkingDirection.BACK:
					play_animation(character_animator, walking_back_animation)
				WalkingDirection.LEFT:
					play_animation(character_animator, walking_left_animation)
				WalkingDirection.RIGHT:
					play_animation(character_animator, walking_right_animation)
				WalkingDirection.DEFAULT:
					play_animation(character_animator, walking_default_animation)
		Behaviour.SWIMMING:
			stop_animation(effect_animator)
			match walking_direction:
				WalkingDirection.FRONT:
					play_animation(character_animator, swiming_front_animation)
				WalkingDirection.BACK:
					play_animation(character_animator, swiming_back_animation)
				WalkingDirection.LEFT:
					play_animation(character_animator, swiming_left_animation)
				WalkingDirection.RIGHT:
					play_animation(character_animator, swiming_right_animation)
				WalkingDirection.DEFAULT:
					play_animation(character_animator, swiming_default_animation)
		Behaviour.MINING:
			play_animation(effect_animator, mining_effect)
			match walking_direction:
				WalkingDirection.FRONT:
					play_animation(character_animator, mining_front_animation)
				WalkingDirection.BACK:
					play_animation(character_animator, mining_back_animation)
				WalkingDirection.LEFT:
					play_animation(character_animator, mining_left_animation)
				WalkingDirection.RIGHT:
					play_animation(character_animator, mining_right_animation)
				WalkingDirection.DEFAULT:
					play_animation(character_animator, mining_default_animation)
		Behaviour.SLEEPING:
			play_animation(effect_animator, sleeping_effect)
			play_animation(character_animator, sleeping_animation)
		Behaviour.EATING:
			play_animation(effect_animator, eating_effect)
			play_animation(character_animator, eating_animation)


func set_behaviour(my_behaviour: Behaviour) -> void:
	set_animation(my_behaviour, walking_direction)

func set_walking_direction(my_direction: WalkingDirection) -> void:
	set_animation(behaviour, my_direction)

func _process(delta):
	if walking_path.size() > 0:
		var target: Vector3i = walking_path[0]
		if (target.z != current_level):
			current_dungeon_layer.dwarf_container.remove_child(self)
			set_current_position(current_position, target.z)
			current_level = target.z
			current_dungeon_layer = world.tile_maps[current_level]
			current_dungeon_layer.dwarf_container.add_child(self)
			walking_path.remove_at(0)
			if walking_path.size() == 0:
				set_animation(Behaviour.IDLE, WalkingDirection.DEFAULT)
			return
		var target2D = world.visible_tile_map.map_to_local(Vector2(target.x, target.y))

		var direction = (target2D - position).normalized()
		var velocity = direction * walking_speed * delta
		
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

		var walking_speed_factor_next: float = data.get_custom_data("walking_speed_factor")
		var is_walkable_next: float = data.get_custom_data("is_walkable")
		var is_water_next: float = data.get_custom_data("is_water")

		var my_behaviour = Behaviour.WALKING

		if is_water_next:
			my_behaviour = Behaviour.SWIMMING
		if !is_walkable_next:
			my_behaviour = Behaviour.MINING

		if direction.x > 0:
			set_animation(my_behaviour, WalkingDirection.RIGHT)
		elif direction.x < 0:
			set_animation(my_behaviour, WalkingDirection.LEFT)
		elif direction.y > 0:
			set_animation(my_behaviour, WalkingDirection.FRONT)
		elif direction.y < 0:
			set_animation(my_behaviour, WalkingDirection.BACK)

		velocity *= walking_speed_factor_next

		position += velocity
		if (position - target2D).length() < 1.0:
			position = target2D
			set_current_position(Vector2(target.x, target.y), current_level)
		
			walking_path.remove_at(0)

			var data_now = world.get_tile_data(current_position, target.z)
			var walkable: bool = data_now.get_custom_data("is_walkable")
			if !walkable:
				world.mine_tile(current_position, current_level)
		
			if walking_path.size() == 0:
				set_animation(Behaviour.IDLE, WalkingDirection.DEFAULT)

func walk_to(target: Vector2, level: int) -> void:
	var current_key = world.get_unique_id(current_position, current_level)
	var target_key = world.get_unique_id(target, level)
	var path = world.astar.get_point_path(current_key, target_key)
	walking_path = path
