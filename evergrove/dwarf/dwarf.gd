extends Node2D

class_name Dwarf

const Utils = preload("../Utils.gd")

@export var current_dungeon_layer: DungeonLayer

@onready var effect_animator: AnimatedSprite2D = $"./EffectAnimator"
@onready var action_effect_animator: AnimatedSprite2D = $"./ActionEffectAnimator"

@onready var energy_bar: ProgressBar = $"./EnergyBar"
@onready var food_bar: ProgressBar = $"./FoodBar"
@onready var beer_bar: ProgressBar = $"./BeerBar"

var body_animator: AnimatedSprite2D
var clothing_animator: AnimatedSprite2D
var hair_animator: AnimatedSprite2D

@onready var game_state: GameState = $"/root/Game/GameState"
@onready var world: World = $"/root/Game/World"

@export var walking_speed: float = 75.0
@export var walking_direction: Utils.WalkingDirection
@export var behaviour: Utils.Behaviour
@export var walking_path: PackedVector3Array = []
@export var current_level: int = 0
@export var current_position: Vector2i = Vector2i(0, 0)
@export var view_range: int = 3

const idle_animation = "idle"
const sleeping_animation = idle_animation
const eating_animation = idle_animation
const drinking_animation = idle_animation
const building_animation = idle_animation

const walking_front_animation = "front"
const walking_back_animation = "back"
const walking_left_animation = "left"
const walking_right_animation = "right"
const walking_default_animation = "idle"

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
const drinking_effect = "drinking_effect"
const sleeping_effect = "sleeping_effect"
const building_effect = "building_effect"

const spawn_effect = "spawn_effect"
const death_effect = "death_effect"

@export var type: DwarfType
@export var skin: DwarfSkin
@export var hair: DwarfHair

enum DwarfType {
	THICC,
	THIN,
}

enum DwarfSkin {
	LIGHT,
	MEDIUM,
	DARK,
}

enum DwarfHair {
	NONE,
	PIGTAILS,
	HAIR_BASE,
	#IRO,
}

@export var action_effect_animator_position: Vector2

func die_dwarf() -> void:
	action_effect_animator.position = action_effect_animator_position + Vector2(0, -Utils.TILE_SIZE_HALF)
	var callback = func():
		game_state.dec_dwarfs(1)
		self.queue_free()
	action_effect_animator.connect("animation_finished", callback)
	play_animation(action_effect_animator, death_effect)

func show_bars(value: bool) -> void:
	energy_bar.visible = value
	food_bar.visible = value
	beer_bar.visible = value

func update_bars(energy: float, food: float, beer: float) -> void:
	energy_bar.value = energy
	food_bar.value = food
	beer_bar.value = beer

func set_current_position(my_position: Vector2i, level: int, force: bool = false) -> void:
	if !force && current_position == my_position && current_level == level:
		return
	current_position = my_position
	current_level = level
	current_dungeon_layer.clear_fow(my_position, view_range)

func _ready():
	action_effect_animator_position = action_effect_animator.position
	var rng = RandomNumberGenerator.new()
	rng.randi_range(0, 1)
	var random_type = rng.randi_range(0, 1)
	match random_type:
		0:
			type = DwarfType.THICC
		1:
			type = DwarfType.THIN
	
	var random_skin = rng.randi_range(0, 2)
	match random_skin:
		0:
			skin = DwarfSkin.LIGHT
		1:
			skin = DwarfSkin.MEDIUM
		2:
			skin = DwarfSkin.DARK	
	
	var random_hair = rng.randi_range(0, 2)
	match random_hair:
		0:
			hair = DwarfHair.NONE
		1:
			hair = DwarfHair.PIGTAILS
		2:
			hair = DwarfHair.HAIR_BASE	

	match type:
		DwarfType.THICC:
			walking_speed = 75.0
			var base = $"./ThiccBase"
			base.visible = true
			hair_animator = $"./ThiccBase/Hair"
			body_animator = $"./ThiccBase/Body"
			clothing_animator = $"./ThiccBase/Clothing"
		DwarfType.THIN:
			walking_speed = 100.0
			var base = $"./ThinBase"
			base.visible = true
			hair_animator = $"./ThinBase/Hair"
			body_animator = $"./ThinBase/Body"
			clothing_animator = $"./ThinBase/Clothing"
		
	var selected_color = rng.randi_range(0, 3)
	if selected_color <= 1:
		# ginger
		hair_animator.modulate = Color8(rng.randi_range(120, 234), 	rng.randi_range(50, 110), 	rng.randi_range(7, 40))
	elif selected_color <= 2:
		# brown
		hair_animator.modulate = Color8(rng.randi_range(102, 107), 	rng.randi_range(57, 103), 	rng.randi_range(25, 54))
	elif selected_color <= 3:
		# blonde
		hair_animator.modulate = Color8(rng.randi_range(175, 255), 	rng.randi_range(120, 193), 	rng.randi_range(0, 95))
		
	clothing_animator.modulate = Color8(rng.randi_range(80, 140), 	rng.randi_range(80, 140), 	rng.randi_range(80, 140))

	set_normal()

	# TODO retrieve walking direction and call play on animated sprite
	# this is just an example how to call animations
	# instantiate AI controller
	if game_state != null:
		add_child(Agent.create())
		game_state.selected_dwarf = self
		game_state.inc_dwarfs(1)
		action_effect_animator.position = action_effect_animator_position + Vector2(0, -Utils.TILE_SIZE_HALF)
		play_animation(action_effect_animator, spawn_effect)
	else:
		show_bars(false)

	print("finish dwarf")

func play_animation(animator: AnimatedSprite2D, animation: String) -> void:
	#if !animator.is_playing() || animator.animation != animation || !animator.visible:
		animator.visible = true
		animator.play(animation)

func stop_animation(animator: AnimatedSprite2D) -> void:
	#if animator.is_playing() || animator.visible:
		animator.stop()
		animator.visible = false

func play_effect(animation: String) -> void:
	play_animation(effect_animator, animation)
	play_animation(action_effect_animator, animation)

	match walking_direction:
		Utils.WalkingDirection.FRONT:
			action_effect_animator.position = action_effect_animator_position + Vector2(0, Utils.TILE_SIZE_HALF)
		Utils.WalkingDirection.BACK:
			action_effect_animator.position = action_effect_animator_position + Vector2(0, -Utils.TILE_SIZE)
		Utils.WalkingDirection.LEFT:
			action_effect_animator.position = action_effect_animator_position + Vector2(-Utils.TILE_SIZE_HALF, 0)
		Utils.WalkingDirection.RIGHT:
			action_effect_animator.position = action_effect_animator_position + Vector2(Utils.TILE_SIZE_HALF, 0)
		Utils.WalkingDirection.DEFAULT:
			action_effect_animator.position = action_effect_animator_position

func stop_effect() -> void:
	stop_animation(effect_animator)
	stop_animation(action_effect_animator)

func play_character_animation(animation: String) -> void:
	var body_animation_name = ""
	match skin:
		DwarfSkin.LIGHT:
			body_animation_name = "light_%s" % [animation]
		DwarfSkin.MEDIUM:
			body_animation_name = "medium_%s" % [animation]
		DwarfSkin.DARK:
			body_animation_name = "dark_%s" % [animation]

	var clothing_animation_name = animation

	var hair_animation_name = ""

	match hair:
		DwarfHair.NONE:
			hair_animation_name = "none_%s" % [animation]
		DwarfHair.PIGTAILS:
			hair_animation_name = "pigtails_base_%s" % [animation]
		DwarfHair.HAIR_BASE:
			hair_animation_name = "hair_base_%s" % [animation]
	
	play_animation(body_animator, body_animation_name)
	play_animation(clothing_animator, clothing_animation_name)
	play_animation(hair_animator, hair_animation_name)

func set_animation(my_behaviour: Utils.Behaviour, my_walking_direction: Utils.WalkingDirection) -> void:
	#print("set_animation")
	if behaviour == my_behaviour && walking_direction == my_walking_direction:
		#print("skip set_animation")
		return	

	behaviour = my_behaviour
	walking_direction = my_walking_direction
	
	match behaviour:
		Utils.Behaviour.IDLE:
			play_character_animation(idle_animation)
			stop_effect()
		Utils.Behaviour.WALKING:
			stop_effect()
			match walking_direction:
				Utils.WalkingDirection.FRONT:
					play_character_animation(walking_front_animation)
				Utils.WalkingDirection.BACK:
					play_character_animation(walking_back_animation)
				Utils.WalkingDirection.LEFT:
					play_character_animation(walking_left_animation)
				Utils.WalkingDirection.RIGHT:
					play_character_animation(walking_right_animation)
				Utils.WalkingDirection.DEFAULT:
					play_character_animation(walking_default_animation)
		Utils.Behaviour.SWIMMING:
			stop_effect()
			match walking_direction:
				Utils.WalkingDirection.FRONT:
					play_character_animation(swiming_front_animation)
				Utils.WalkingDirection.BACK:
					play_character_animation(swiming_back_animation)
				Utils.WalkingDirection.LEFT:
					play_character_animation(swiming_left_animation)
				Utils.WalkingDirection.RIGHT:
					play_character_animation(swiming_right_animation)
				Utils.WalkingDirection.DEFAULT:
					play_character_animation(swiming_default_animation)
		Utils.Behaviour.MINING:
			play_effect(mining_effect)
			match walking_direction:
				Utils.WalkingDirection.FRONT:
					play_character_animation(mining_front_animation)
				Utils.WalkingDirection.BACK:
					play_character_animation(mining_back_animation)
				Utils.WalkingDirection.LEFT:
					play_character_animation(mining_left_animation)
				Utils.WalkingDirection.RIGHT:
					play_character_animation(mining_right_animation)
				Utils.WalkingDirection.DEFAULT:
					play_character_animation(mining_default_animation)
		Utils.Behaviour.SLEEPING:
			play_effect(sleeping_effect)
			play_character_animation(sleeping_animation)
		Utils.Behaviour.EATING:
			play_effect(eating_effect)
			play_character_animation(eating_animation)
		Utils.Behaviour.DRINKING:
			play_effect(drinking_effect)
			play_character_animation(drinking_animation)
		Utils.Behaviour.BUILDING:
			play_effect(building_effect)
			play_character_animation(building_animation)

func set_sleeping():
	set_animation(Utils.Behaviour.SLEEPING, Utils.WalkingDirection.DEFAULT)

func set_eating():
	set_animation(Utils.Behaviour.EATING, Utils.WalkingDirection.DEFAULT)

func set_drinking():
	set_animation(Utils.Behaviour.DRINKING, Utils.WalkingDirection.DEFAULT)

func set_normal():
	set_animation(Utils.Behaviour.IDLE, Utils.WalkingDirection.DEFAULT)

func set_building():
	set_animation(Utils.Behaviour.BUILDING, Utils.WalkingDirection.DEFAULT)

func set_behaviour(my_behaviour: Utils.Behaviour) -> void:
	set_animation(my_behaviour, walking_direction)

func set_walking_direction(my_direction: Utils.WalkingDirection) -> void:
	set_animation(behaviour, my_direction)

func _process(delta):
	if walking_path.size() > 0:
		var target: Vector3i = Utils.convert_from_astar(walking_path[0])
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

		var next_position = Vector2i(target.x, target.y)

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

		var next_direction = (target2D - position).normalized()

		if position.distance_to(target2D) < 0.5 || direction.distance_to(next_direction) > 0:
			position = target2D
			set_current_position(Vector2(target.x, target.y), current_level)
			
			walking_path.remove_at(0)
			
			var data_now = world.get_tile_data(current_position, target.z)
			var walkable: bool = data_now.get_custom_data("is_walkable")
			if !walkable:
				world.mine_tile(current_position, current_level)
			
			if walking_path.size() == 0:
				set_animation(Utils.Behaviour.IDLE, Utils.WalkingDirection.DEFAULT)

func walk_to(target: Vector2i, level: int = current_level) -> Vector3i:
	print("walk_to")
	if (walking_path.size() > 0):
		print("Already walking")
	
	var pos = Utils.convert_to_v3_astar(target, level)
	var id = world.astar.get_closest_point(pos)
	var target_point_astar = world.astar.get_point_position(id);
	var target_point: Vector3i = Utils.convert_from_astar(target_point_astar)

	var current_key = world.get_unique_id(current_position, current_level)
	var target_key = world.get_unique_id(Vector2i(target_point.x, target_point.y), target_point.z)
	var path = world.astar.get_point_path(current_key, target_key)

	walking_path = path

	return target_point
