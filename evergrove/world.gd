extends Node2D

class_name World

const Utils = preload("./Utils.gd")

const HALF_CHUNK_SIZE = 64
const CHUNK_SIZE = HALF_CHUNK_SIZE * 2
const LEVELS = 5

enum TileType {
	AIR 		= 0,
	DIRT 		= 1,
	STONE 		= 2,
	COAL 		= 3,
	IRON 		= 4,
	COPPER 		= 5,
	SILVER 		= 6,
	GOLD 		= 7,
	GEM 		= 8,
	LADDER_DOWN = 9,
	LADDER_UP 	= 10,
	WATER 		= 11,
	MICEL 		= 12,
}

@export var GLOBAL_SEED = 12345

@onready var camera: Camera2D = $"/root/Game/Camera2D"
@onready var game_state: GameState = $"/root/Game/GameState"
@onready var select_cursor: Sprite2D = $"./TileCursor"
@onready var build_cursor: BuildingCursor = $"./BuildingCursor"

@export var visible_tile_map: DungeonLayer
@export var visible_level: int

@export var tile_maps: Dictionary = {}
@export var tile_type_to_id: Dictionary = {}

@export var visible_rect: Rect2

@export var point_dicrionary: Dictionary = {}

@export var is_generating_fog_of_war: bool = true
@export var is_active_debug_input: bool = true

var astar: AStar3D

var sprite_texture = preload("res://cross.png")

@export var cursor_type: Utils.CursorType = Utils.CursorType.SELECT
@export var build_type: Utils.BuildingType = Utils.BuildingType.BEER

func _ready():
	for tile_type in TileType.values():
		var tile_id = tile_type  # Verwende die Position im Enum als Tile-ID
		tile_type_to_id[tile_type] = tile_id

	astar = AStar3D.new()

	for level in range(LEVELS):		
		var tile_map : DungeonLayer  = preload("res://map/DungeonLayer.tscn").instantiate()
		
		tile_map.init(GLOBAL_SEED + 25 * level, level)

		tile_maps[level] = tile_map
		
		add_child(tile_map)
		# Generiere initiale Chunks
		# generate_tile(tile_map, Vector2i(0, 0))

	var start_map = tile_maps[0]
	set_air_around_tile(start_map, Vector2i(0, 0), false)
	set_active_level(0)
	set_cursor_type(Utils.CursorType.SELECT)

	# 
	#
	# var start_key = get_unique_id(Vector2i(20, 20), 0)
	# var end_key = get_unique_id(Vector2i(-20, -20), 0)
	
	# var path = astar.get_point_path(start_key, end_key)
	
	# for point in path:
	# 	var sprite = Sprite2D.new()
	# 	sprite.texture = sprite_texture
	# 	add_child(sprite)
	# 	sprite.z_index = 100
	# 	sprite.position = visible_tile_map.map_to_local(Vector2i(point.x, point.y))
		
	
func set_active_level(my_level: int):
	#print("set active level: %d" % [my_level])
	if (my_level < 0 || my_level >= LEVELS):
		return
	visible_tile_map = tile_maps[my_level]
	for level in tile_maps.keys():
		tile_maps[level].visible = false
	visible_tile_map.visible = true
	visible_level = my_level
	game_state.set_current_level(my_level)
	check_visible_tiles(true)

func set_air_around_tile(tile_map: TileMap, pos: Vector2i, skip_center: bool = true):
	for x in range(-1, 2):
		for y in range(-1, 2):
			var new_pos = pos + Vector2i(x, y)
			if (skip_center && new_pos == pos):
				continue
			if tile_map.get_cell_source_id(0, new_pos) == -1:
				tile_map.set_cell(0, new_pos, 0, Vector2i(0, TileType.AIR))

func generate_fog_of_war(tile_map: DungeonLayer, pos: Vector2i):
	if is_generating_fog_of_war:
		tile_map.set_cell(1, pos, 1, Vector2i(0, 0))

func generate_tile(tile_map: DungeonLayer, pos: Vector2i):
	if tile_map.get_cell_source_id(0, pos) != -1:
		return

	var terrain_noise = tile_map.terrain_noise
	var ore_noise = tile_map.ore_noise
	#var height = int(terrain_noise.get_noise_2d(global_x, global_y) * 10) + 10
	var tile_type = TileType.AIR
	var terrain_noise_value = terrain_noise.get_noise_2d(pos.x, pos.y)
	# Bestimme den Tile-Typ basierend auf verschiedenen Noise-Werten
	if terrain_noise_value < -0.75:
		tile_type = TileType.WATER
	elif terrain_noise_value < -0.55:
		tile_type = TileType.AIR
		if (randf() < 0.05):
			var curr_level = tile_map.level
			if (tile_maps[curr_level + 1]):
				var below_map = tile_maps[curr_level + 1]
				if (below_map.get_cell_source_id(0, pos) == -1):
					var distance = tile_map.min_distance_to_ladder(pos)
					if (distance > 25):
						below_map.set_cell(0, pos, 0, Vector2i(0, TileType.LADDER_UP))
						set_air_around_tile(below_map, pos)
						tile_type = TileType.LADDER_DOWN
						tile_map.ladder[pos] = true
	else:
		tile_type = TileType.STONE
		var ore_value = ore_noise.get_noise_2d(pos.x, pos.y)
		if ore_value > 0.95:
			tile_type = TileType.GEM
		elif ore_value > 0.7:
			tile_type = TileType.STONE
		elif ore_value > 0.65:
			tile_type = TileType.GOLD
		elif ore_value > 0.6:
			tile_type = TileType.STONE
		elif ore_value > 0.5:
			tile_type = TileType.SILVER
		elif ore_value > 0.41:
			tile_type = TileType.STONE
		elif ore_value > 0.35:
			tile_type = TileType.COPPER
		elif ore_value > 0.29:
			tile_type = TileType.STONE
		elif ore_value > 0.25:
			tile_type = TileType.IRON
		elif ore_value > 0.2:
			tile_type = TileType.STONE
		elif ore_value > 0.18:
			tile_type = TileType.MICEL
		elif ore_value > 0.1:
			tile_type = TileType.STONE
		elif ore_value > 0.07:
			tile_type = TileType.MICEL
		elif ore_value > 0.0:
			tile_type = TileType.STONE
		else:
			tile_type = TileType.DIRT
			
	var atlas_coord = Vector2i(0, tile_type_to_id[tile_type])

	tile_map.set_cell(0, pos, 0, atlas_coord)


func _process(delta):
	check_visible_tiles()

func check_visible_tiles(force: bool = false):
	# Bestimme den sichtbaren Bereich der Kamera
	var zoom = camera.zoom
	var viewport_size = camera.get_viewport_rect().size
	var visible_rect_size = viewport_size / zoom
	var visible_rect_position = camera.position - visible_rect_size / 2
	var current_visible_rect = Rect2(visible_rect_position, visible_rect_size)

	#var current_visible_rect = Rect2(camera.position - camera.zoom * camera.get_viewport_rect().size / 2, camera.zoom * camera.get_viewport_rect().size)

	if (!force && current_visible_rect == visible_rect):
		return

	visible_rect = current_visible_rect

	# Berechne die sichtbaren Kacheln in der TileMap
	var start_x = int(floor(visible_rect.position.x / (Utils.TILE_SIZE * CHUNK_SIZE)))
	var start_y = int(floor(visible_rect.position.y / (Utils.TILE_SIZE * CHUNK_SIZE)))
	var end_x = int(ceil((visible_rect.position.x + visible_rect.size.x) / (Utils.TILE_SIZE * CHUNK_SIZE))) + 1
	var end_y = int(ceil((visible_rect.position.y + visible_rect.size.y) / (Utils.TILE_SIZE * CHUNK_SIZE))) + 1

	# Überprüfe und generiere die Chunks für die sichtbaren Kacheln
	for x in range(start_x, end_x):
		for y in range(start_y, end_y):
			var chunk = Vector2i(x, y)
			if visible_tile_map.chunks.has(chunk):
				continue
			visible_tile_map.chunks[chunk] = true
			for chunk_x in range(-HALF_CHUNK_SIZE, HALF_CHUNK_SIZE):
				for chunk_y in range(-HALF_CHUNK_SIZE, HALF_CHUNK_SIZE):
					var pos = Vector2i(x * CHUNK_SIZE + chunk_x, y * CHUNK_SIZE + chunk_y)
					generate_tile(visible_tile_map, pos)
					generate_fog_of_war(visible_tile_map, pos)
					update_astarGrid(visible_tile_map, visible_level, pos)
			#generate_tile(visible_tile_map, Vector2i(x, y))

func set_cursor_type(type: Utils.CursorType, build_type: Utils.BuildingType = Utils.BuildingType.BEER):
	cursor_type = type
	build_cursor.set_building_type(build_type)
	select_cursor.visible = cursor_type == Utils.CursorType.SELECT
	build_cursor.visible = cursor_type == Utils.CursorType.BUILD

func handle_cursor(event: InputEvent):
	match cursor_type:
		Utils.CursorType.SELECT:
			var tile_position = visible_tile_map.local_to_map(get_global_mouse_position())
			select_cursor.position = visible_tile_map.map_to_local(tile_position)
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					var marker = Sprite2D.new()
					marker.texture = sprite_texture
					visible_tile_map.add_child(marker)

					marker.z_index = 100
					marker.position = select_cursor.position

					var remove_callback: Callable = func (dwarf):
						#print("callback!!!!")
						marker.queue_free()

					var task: Task = Task.create(ai_globals.TASK_TYPE.MOVE_TO, "", 0, ai_globals.Location.create(tile_position, visible_level), remove_callback)
					ai_globals.hivemind.add_task(task)

			#if is_active_debug_input && event is InputEventMouseButton:
			#	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			#		var selected_dwarf = game_state.selected_dwarf
			#		if selected_dwarf:
			#			var target_pos = visible_tile_map.local_to_map(get_global_mouse_position())
			#			selected_dwarf.walk_to(target_pos, visible_level)
			#		else:
			#			var pos = visible_tile_map.local_to_map(get_global_mouse_position())
			#			mine_tile(pos, visible_level)
			#if is_active_debug_input && event is InputEventKey:
			#	if event.pressed:
			#		if event.keycode == KEY_G:
			#			var dwarf = game_state.selected_dwarf
			#			var next_point: Vector2 = get_nearest_building(Utils.BuildingType.FOOD, dwarf.current_position, dwarf.current_level)
			#			if next_point:
			#				dwarf.walk_to(Vector2i(next_point.x, next_point.y))
		Utils.CursorType.BUILD:
			var tile_position = visible_tile_map.local_to_map(get_global_mouse_position())
			build_cursor.set_tile(tile_position)
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					build_cursor.build()


func _unhandled_input(event: InputEvent) -> void:
	handle_cursor(event)
	
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_Q:
				set_active_level(visible_level - 1)
			elif event.keycode == KEY_E:
				set_active_level(visible_level + 1)
			elif event.keycode == KEY_C:
				set_cursor_type(Utils.CursorType.SELECT)
			#elif event.keycode == KEY_F:
				#set_cursor_type(Utils.CursorType.BUILD, Utils.BuildingType.FOOD)
			#elif event.keycode == KEY_B:
				#set_cursor_type(Utils.CursorType.BUILD, Utils.BuildingType.BEER)
			#lif event.keycode == KEY_P:
				#set_cursor_type(Utils.CursorType.BUILD, Utils.BuildingType.ENERGY)

func create_poit(pos: Vector3i, cost: float) -> int:
	var key = get_unique_id_v3(pos)
	if (!astar.has_point(key)):
		astar.add_point(key, pos, cost)
		#print("add point %v with key %d" % [pos, key])
	else :
		astar.set_point_weight_scale(key, cost)
		#print("update point %v with key %d" % [pos, key])
	return key

func connect_adjacent_tiles(pos: Vector2i, level: int):
	var directions = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	var key = get_unique_id(pos, level)
	for direction in directions:
		var new_pos = pos + direction
		var new_key = get_unique_id(new_pos, level, true)
		if new_key > 0 && astar.has_point(new_key):
			astar.connect_points(key, new_key)

func update_astarGrid(tile_map: DungeonLayer, level: int, pos: Vector2i):
	var data: TileData = tile_map.get_cell_tile_data(0, pos)
	if !data:
		return

	var cost: float = data.get_custom_data("cost")
	var connect_up: bool = data.get_custom_data("connect_up")
	var connect_down: bool = data.get_custom_data("connect_down")

	var pos_astar = Utils.convert_to_v3_astar(pos, level)
	var pos_key = create_poit(pos_astar, cost)
	connect_adjacent_tiles(pos, level)
	if connect_up:
		if level > 0:
			var pos_up_astar = Utils.convert_to_v3_astar(pos, level - 1)
			var pos_up_key = create_poit(pos_up_astar, cost)
			astar.connect_points(pos_key, pos_up_key)
			tile_map.up_ladder_astar.add_point(pos_key, pos)
	if connect_down:
		if level < LEVELS - 1:
			var pos_down_astar = Utils.convert_to_v3_astar(pos, level + 1)
			var pos_down_key = create_poit(pos_down_astar, cost)
			astar.connect_points(pos_key, pos_down_key)
			tile_map.down_ladder_astar.add_point(pos_key, pos)

func mine_tile(pos: Vector2i, level: int):
	var tile_map = tile_maps[level]
	var data: TileData = tile_map.get_cell_tile_data(0, pos)
	if !data:
		return
	var has_resource = data.get_custom_data("has_resource")
	var resource_type = data.get_custom_data("resource_type")
	var min_resource = data.get_custom_data("min_resource")
	var max_resource = data.get_custom_data("max_resource")
	
	var consumed = data.get_custom_data("consumed")

	if has_resource:
		var resource = randi() % (max_resource - min_resource) + min_resource
		if resource > 0:
			match resource_type:
				TileType.DIRT:
					game_state.inc_dirt(resource)
				TileType.STONE:
					game_state.inc_stone(resource)
				TileType.COAL:
					game_state.inc_coal(resource)
				TileType.IRON:
					game_state.inc_iron(resource)
				TileType.COPPER:
					game_state.inc_copper(resource)
				TileType.SILVER:
					game_state.inc_silver(resource)
				TileType.GOLD:
					game_state.inc_gold(resource)
				TileType.GEM:
					game_state.inc_gem(resource)
				TileType.WATER:
					game_state.inc_water(resource)
				TileType.MICEL:
					game_state.inc_micel(resource)
		if consumed:
			tile_map.set_cell(0, pos, 0, Vector2i(0, TileType.AIR))
			update_astarGrid(tile_map, level, pos)

func get_unique_id_v3(vector: Vector3i, read_only: bool = false) -> int:
	if point_dicrionary.has(vector):
		return point_dicrionary[vector]
	if read_only:
		return -1
	var id = astar.get_available_point_id()
	point_dicrionary[vector] = id
	return id

func get_unique_id(pos: Vector2i, level: int, read_only: bool = false) -> int:
	var vector: Vector3i = Utils.convert_to_v3_astar(pos, level)
	return get_unique_id_v3(vector, read_only)

func get_tile_data(pos: Vector2i, level: int = visible_level) -> TileData:
	var tile_map = tile_maps[level]
	return tile_map.get_cell_tile_data(0, pos)

func is_free_space(pos: Vector2i, level: int = visible_level) -> bool:
	var tile_map: DungeonLayer = tile_maps[level]
	var data = tile_map.get_cell_tile_data(0, pos)
	var blocked = tile_map.blocked_space.has(pos)
	var free_space: bool = data.get_custom_data("is_free_space")

	return free_space && !blocked

func build_building(building_type: Utils.BuildingType, my_position: Vector2, tiles: Dictionary, level: int = visible_level):
	var tile_map = tile_maps[level]
	
	tile_map.build_building(building_type, my_position, tiles)
	for tile in tiles.keys():
		var point = Utils.convert_to_v3_astar(tile, level)
		var key = get_unique_id_v3(point)
		astar.remove_point(key)
		point_dicrionary.erase(point)

	set_cursor_type(Utils.CursorType.SELECT)

# return Vector3i
func get_nearest_building(type: Utils.BuildingType, pos: Vector2i, level: int = visible_level):
	if level < 0 || level >= LEVELS:
		return null

	var tile_map = tile_maps[level]
	
	match type:
		Utils.BuildingType.FOOD:
			var key = tile_map.food_astar.get_closest_point(pos)
			if key < 0:
				return null
			return Utils.convert_to_v3(tile_map.food_astar.get_point_position(key), level)
		Utils.BuildingType.BEER:
			var key = tile_map.beer_astar.get_closest_point(pos)
			if key < 0:
				return null
			return Utils.convert_to_v3(tile_map.beer_astar.get_point_position(key), level)
		Utils.BuildingType.ENERGY:
			var key = tile_map.energy_astar.get_closest_point(pos)
			if key < 0:
				return null
			return Utils.convert_to_v3(tile_map.energy_astar.get_point_position(key), level)

# return Vector3i
func get_nearest_building_location_retry(type: Utils.BuildingType, pos: Vector2i, level: int = visible_level):
	var search_pattern = []
	search_pattern.append(level)
	for x in range(1, LEVELS):
		if level - x >= 0:
			search_pattern.append(level - x)
		if level + x < LEVELS:
			search_pattern.append(level + x)
	
	for search_level in search_pattern:
		var location = get_nearest_building(type, pos, search_level)
		if location:
			return location
