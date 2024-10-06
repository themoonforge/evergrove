extends Node2D

class_name World

const TILE_SIZE = 16
const HALF_CHUNK_SIZE = 64
const CHUNK_SIZE = HALF_CHUNK_SIZE * 2
const LAYERS = 5

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
@onready var tile_cursor: Sprite2D = $"./TileCursor"

@export var visible_tile_map: DungeonLayer
@export var visible_level: int

@export var tile_maps: Dictionary = {}
@export var tile_type_to_id: Dictionary = {}

@export var tile_set: TileSet
@export var visible_rect: Rect2

@export var point_dicrionary: Dictionary = {}

@export var is_generating_fog_of_war: bool = true
@export var is_active_debug_input: bool = true

var astar: AStar3D

var sprite_texture = preload("res://cross.png")

func _ready():
	tile_set = preload("res://tile_set.tres")
	for tile_type in TileType.values():
		var tile_id = tile_type  # Verwende die Position im Enum als Tile-ID
		tile_type_to_id[tile_type] = tile_id

	astar = AStar3D.new()

	for layer in range(LAYERS):
		#var tile_map = TileMap.new()
		#tile_map.tile_set = tile_set
		
		var tile_map : DungeonLayer  = preload("res://map/DungeonLayer.tscn").instantiate()
		tile_map.tile_set = tile_set
		
		tile_map.init(GLOBAL_SEED + 25 * layer, layer)

		tile_maps[layer] = tile_map
		
		add_child(tile_map)
		# Generiere initiale Chunks
		# generate_tile(tile_map, Vector2i(0, 0))

	var start_map = tile_maps[0]
	set_air_around_tile(start_map, Vector2i(0, 0), false)
	set_active_level(0)

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
		
	
func set_active_level(level: int):
	print("set active layer: %d" % [level])
	if (level < 0 or level >= LAYERS):
		return
	visible_tile_map = tile_maps[level]
	for layer in tile_maps.keys():
		tile_maps[layer].visible = false
	visible_tile_map.visible = true
	visible_level = level
	game_state.set_current_level(level)
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
			var curr_layer = tile_map.level
			if (tile_maps[curr_layer + 1]):
				var below_map = tile_maps[curr_layer + 1]
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
	var start_x = int(floor(visible_rect.position.x / (TILE_SIZE * CHUNK_SIZE)))
	var start_y = int(floor(visible_rect.position.y / (TILE_SIZE * CHUNK_SIZE)))
	var end_x = int(ceil((visible_rect.position.x + visible_rect.size.x) / (TILE_SIZE * CHUNK_SIZE))) + 1
	var end_y = int(ceil((visible_rect.position.y + visible_rect.size.y) / (TILE_SIZE * CHUNK_SIZE))) + 1

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var tile_position = visible_tile_map.local_to_map(get_global_mouse_position())
		tile_cursor.position = visible_tile_map.map_to_local(tile_position)
	
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_Q:
				set_active_level(visible_level - 1)
			elif event.keycode == KEY_E:
				set_active_level(visible_level + 1)

	if is_active_debug_input && event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var selected_dwarf = game_state.selected_dwarf
			if selected_dwarf:
				var target_pos = visible_tile_map.local_to_map(get_global_mouse_position())
				selected_dwarf.walk_to(target_pos, visible_level)
			else:
				var pos = visible_tile_map.local_to_map(get_global_mouse_position())
				mine_tile(pos, visible_level)

func create_poit(pos: Vector2i, level: int, cost: float):
	var key = get_unique_id(pos, level)
	if (!astar.has_point(key)):
		astar.add_point(key, Vector3(pos.x, pos.y, level), cost)

func connect_adjacent_tiles(pos: Vector2i, level: int):
	var directions = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	var key = get_unique_id(pos, level)
	for direction in directions:
		var new_pos = pos + direction
		var new_key = get_unique_id(new_pos, level, true)
		if new_key > 0 && astar.has_point(new_key):
			astar.connect_points(key, new_key)

func update_astarGrid(tile_map: TileMap, level: int, pos: Vector2i):
	var data: TileData = tile_map.get_cell_tile_data(0, pos)
	if !data:
		return

	var cost: float = data.get_custom_data("cost")
	var connect_up: bool = data.get_custom_data("connect_up")
	var connect_down: bool = data.get_custom_data("connect_down")
	create_poit(pos, level, cost)
	connect_adjacent_tiles(pos, level)
	if connect_up:
		if level > 0:
			create_poit(pos, level - 1, cost)
			astar.connect_points(get_unique_id(pos, level), get_unique_id(pos, level - 1))
	if connect_down:
		if level < LAYERS - 1:
			create_poit(pos, level + 1, cost)
			astar.connect_points(get_unique_id(pos, level), get_unique_id(pos, level + 1))

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
					game_state.set_dirt(game_state.dirt + resource)
				TileType.STONE:
					game_state.set_stone(game_state.stone + resource)
				TileType.COAL:
					game_state.set_coal(game_state.coal + resource)
				TileType.IRON:
					game_state.set_iron(game_state.iron + resource)
				TileType.COPPER:
					game_state.set_copper(game_state.copper + resource)
				TileType.SILVER:
					game_state.set_silver(game_state.silver + resource)
				TileType.GOLD:
					game_state.set_gold(game_state.gold + resource)
				TileType.GEM:
					game_state.set_gem(game_state.gem + resource)
				TileType.WATER:
					game_state.set_water(game_state.water + resource)
				TileType.MICEL:
					game_state.set_micel(game_state.micel + resource)
		if consumed:
			tile_map.set_cell(0, pos, 0, Vector2i(0, TileType.AIR))
			update_astarGrid(tile_map, level, pos)

func get_unique_id(pos: Vector2i, level: int, read_only: bool = false) -> int:
	var vector = Vector3i(pos.x, pos.y, level)
	if point_dicrionary.has(vector):
		return point_dicrionary[vector]
	if read_only:
		return -1
	var id = astar.get_available_point_id()
	point_dicrionary[vector] = id
	return id

func get_tile_data(pos: Vector2i, level: int) -> TileData:
	var tile_map = tile_maps[level]
	return tile_map.get_cell_tile_data(0, pos)
