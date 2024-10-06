extends Node2D

class_name Dwarf

const Utils = preload("../Utils.gd")

@export var current_dungeon_layer: DungeonLayer

@onready var character_animator: AnimatedSprite2D = $"./CharacterAnimator"
@onready var effect_animator: AnimatedSprite2D = $"./EffectAnimator"

@onready var game_state: GameState = $"/root/Game/GameState"
@onready var world: World = $"/root/Game/World"

@export var walking_speed: float = 75.0
@export var walking_direction: Utils.WalkingDirection = Utils.WalkingDirection.DEFAULT
@export var behaviour: Utils.Behaviour = Utils.Behaviour.IDLE
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

var typ: DwarfType
var skin: DwarfSkin
var hair: DwarfType

enum DwarfType {
	THICC,
	THIN
}

enum DwarfSkin {
	LIGHT,
	MEDIUM,
	DARK
}

enum DwarfHair {
	NONE,
	PIGTAILS,
	IRO
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
	set_animation(Utils.Behaviour.IDLE, Utils.WalkingDirection.DEFAULT)

func play_animation(animator: AnimatedSprite2D, animation: String) -> void:
	if !animator.is_playing() || animator.animation != animation || !animator.visible:
		animator.visible = true
		animator.play(animation)

func stop_animation(animator: AnimatedSprite2D) -> void:
	if animator.is_playing() || animator.visible:
		animator.stop()
		animator.visible = false

func set_animation(my_behaviour: Utils.Behaviour, my_walking_direction: Utils.WalkingDirection) -> void:
	if behaviour == my_behaviour && walking_direction == my_walking_direction:
		return	

	behaviour = my_behaviour
	walking_direction = my_walking_direction
	
	match behaviour:
		Utils.Behaviour.IDLE:
			play_animation(character_animator, idle_animation)
			stop_animation(effect_animator)
		Utils.Behaviour.WALKING:
			stop_animation(effect_animator)
			match walking_direction:
				Utils.WalkingDirection.FRONT:
					play_animation(character_animator, walking_front_animation)
				Utils.WalkingDirection.BACK:
					play_animation(character_animator, walking_back_animation)
				Utils.WalkingDirection.LEFT:
					play_animation(character_animator, walking_left_animation)
				Utils.WalkingDirection.RIGHT:
					play_animation(character_animator, walking_right_animation)
				Utils.WalkingDirection.DEFAULT:
					play_animation(character_animator, walking_default_animation)
		Utils.Behaviour.SWIMMING:
			stop_animation(effect_animator)
			match walking_direction:
				Utils.WalkingDirection.FRONT:
					play_animation(character_animator, swiming_front_animation)
				Utils.WalkingDirection.BACK:
					play_animation(character_animator, swiming_back_animation)
				Utils.WalkingDirection.LEFT:
					play_animation(character_animator, swiming_left_animation)
				Utils.WalkingDirection.RIGHT:
					play_animation(character_animator, swiming_right_animation)
				Utils.WalkingDirection.DEFAULT:
					play_animation(character_animator, swiming_default_animation)
		Utils.Behaviour.MINING:
			play_animation(effect_animator, mining_effect)
			match walking_direction:
				Utils.WalkingDirection.FRONT:
					play_animation(character_animator, mining_front_animation)
				Utils.WalkingDirection.BACK:
					play_animation(character_animator, mining_back_animation)
				Utils.WalkingDirection.LEFT:
					play_animation(character_animator, mining_left_animation)
				Utils.WalkingDirection.RIGHT:
					play_animation(character_animator, mining_right_animation)
				Utils.WalkingDirection.DEFAULT:
					play_animation(character_animator, mining_default_animation)
		Utils.Behaviour.SLEEPING:
			play_animation(effect_animator, sleeping_effect)
			play_animation(character_animator, sleeping_animation)
		Utils.Behaviour.EATING:
			play_animation(effect_animator, eating_effect)
			play_animation(character_animator, eating_animation)


func set_behaviour(my_behaviour: Utils.Behaviour) -> void:
	set_animation(my_behaviour, walking_direction)

func set_walking_direction(my_direction: Utils.WalkingDirection) -> void:
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
				set_animation(Utils.Behaviour.IDLE, Utils.WalkingDirection.DEFAULT)
			return
		var target2D = world.visible_tile_map.map_to_local(Vector2(target.x, target.y))

		var direction = (target2D - position).normalized()
		var velocity = direction * walking_speed * delta
		
		var offset = Vector2i(0, 0)
		match walking_direction:
			Utils.WalkingDirection.FRONT:
				offset.y = 1
			Utils.WalkingDirection.BACK:
				offset.y = -1
			Utils.WalkingDirection.LEFT:
				offset.x = -1
			Utils.WalkingDirection.RIGHT:
				offset.x = 1

		var next_position = current_position + offset

		var data = world.get_tile_data(next_position, target.z)

		var walking_speed_factor_next: float = data.get_custom_data("walking_speed_factor")
		var is_walkable_next: float = data.get_custom_data("is_walkable")
		var is_water_next: float = data.get_custom_data("is_water")

		var my_behaviour = Utils.Behaviour.WALKING

		if is_water_next:
			my_behaviour = Utils.Behaviour.SWIMMING
		if !is_walkable_next:
			my_behaviour = Utils.Behaviour.MINING

		if direction.x > 0:
			set_animation(my_behaviour, Utils.WalkingDirection.RIGHT)
		elif direction.x < 0:
			set_animation(my_behaviour, Utils.WalkingDirection.LEFT)
		elif direction.y > 0:
			set_animation(my_behaviour, Utils.WalkingDirection.FRONT)
		elif direction.y < 0:
			set_animation(my_behaviour, Utils.WalkingDirection.BACK)

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
				set_animation(Utils.Behaviour.IDLE, Utils.WalkingDirection.DEFAULT)

func walk_to(target: Vector2, level: int) -> void:
	print("walk_to")
	if (walking_path.size() > 0):
		print("Already walking")
	var current_key = world.get_unique_id(current_position, current_level)
	var target_key = world.get_unique_id(target, level)
	var path = world.astar.get_point_path(current_key, target_key)
	walking_path = path
