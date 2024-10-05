extends Node2D

class_name World

const TILE_SIZE = 16
const HALF_CHUNK_SIZE = 64
const CHUNK_SIZE = HALF_CHUNK_SIZE * 2
const GLOBAL_SEED = 12345
const SCALE = 64.0
const ORE_SCALE = 32.0
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

@onready var camera: Camera2D = $"../Camera2D"

@export var visible_tile_map: TileMap
@export var visible_level: int

@export var tile_maps: Dictionary = {}
@export var tile_maps_level: Dictionary = {}
@export var tile_maps_ladder: Dictionary = {}
@export var tile_maps_chunks: Dictionary = {}
@export var tile_maps_terrain_noise: Dictionary = {}
@export var tile_maps_ore_noise: Dictionary = {}
@export var tile_maps_cave_noise: Dictionary = {}
@export var tile_maps_river_noise: Dictionary = {}
@export var tile_type_to_id: Dictionary = {}
var tile_set: TileSet

@export var visible_rect: Rect2

func init_noise(tile_map: TileMap, seed: int): 
	var terrain_noise = FastNoiseLite.new()
	terrain_noise.seed = seed
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	terrain_noise.frequency = 1.0 / SCALE
	terrain_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	terrain_noise.fractal_octaves = 4
	terrain_noise.fractal_gain = 0.5
	terrain_noise.fractal_lacunarity = 2.0

	var ore_noise = FastNoiseLite.new()
	ore_noise.seed = seed + 1
	ore_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	ore_noise.frequency = 1.0 / ORE_SCALE
	ore_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	ore_noise.fractal_octaves = 4
	ore_noise.fractal_gain = 0.5
	ore_noise.fractal_lacunarity = 2.0

	tile_maps_terrain_noise[tile_map] = terrain_noise
	tile_maps_ore_noise[tile_map] = ore_noise		

func _ready():
	tile_set = preload("res://tile_set.tres")
	for tile_type in TileType.values():
		var tile_id = tile_type  # Verwende die Position im Enum als Tile-ID
		tile_type_to_id[tile_type] = tile_id

	for layer in range(LAYERS):
		#var tile_map = TileMap.new()
		#tile_map.tile_set = tile_set
		
		var tile_map = preload("res://map/DungeonLayer.tscn").instantiate()
		tile_map.tile_set = tile_set
		
		tile_maps[layer] = tile_map
		tile_maps_level[tile_map] = layer
		tile_maps_chunks[tile_map] = {}
		tile_maps_ladder[tile_map] = {}



		add_child(tile_map)
		init_noise(tile_map, GLOBAL_SEED + layer * 20)
		# Generiere initiale Chunks
		#generate_tile(tile_map, Vector2i(0, 0))
	set_active_level(0)
	
func set_active_level(level: int):
	print("set active layer: %d" % [level])
	if (level < 0 or level >= LAYERS):
		return
	visible_tile_map = tile_maps[level]
	for layer in tile_maps.keys():
		tile_maps[layer].visible = false
	visible_tile_map.visible = true
	visible_level = level
	check_visible_tiles(true)
	
func distance_beween_tiles(pos1: Vector2i, pos2: Vector2i):
	return sqrt(pow(pos1.x - pos2.x, 2) + pow(pos1.y - pos2.y, 2))

func min_distance_to_ladder(pos: Vector2i, tile_map: TileMap):
	var min_distance = 1000000
	for ladder_pos in tile_maps_ladder[tile_map].keys():
		var distance = distance_beween_tiles(pos, ladder_pos)
		if distance < min_distance:
			min_distance = distance
	return min_distance

func set_air_around_tile(tile_map: TileMap, pos: Vector2i):
	for x in range(-1, 2):
		for y in range(-1, 2):
			var new_pos = pos + Vector2i(x, y)
			if (new_pos == pos):
				continue
			if tile_map.get_cell_source_id(0, new_pos) == -1:
				tile_map.set_cell(0, new_pos, 0, Vector2i(0, TileType.AIR))

func generate_tile(tile_map: TileMap, pos: Vector2i):
	if tile_map.get_cell_source_id(0, pos) != -1:
		return

	var terrain_noise = tile_maps_terrain_noise[tile_map]
	var ore_noise = tile_maps_ore_noise[tile_map]
	#var height = int(terrain_noise.get_noise_2d(global_x, global_y) * 10) + 10
	var tile_type = TileType.AIR
	var terrain_noise_value = terrain_noise.get_noise_2d(pos.x, pos.y)
	# Bestimme den Tile-Typ basierend auf verschiedenen Noise-Werten
	if terrain_noise_value < -0.75:
		tile_type = TileType.WATER
	elif terrain_noise_value < -0.55:
		tile_type = TileType.AIR
		if (randf() < 0.05):
			var curr_layer = tile_maps_level[tile_map]
			if (tile_maps[curr_layer + 1]):
				var below_map = tile_maps[curr_layer + 1]
				if (below_map.get_cell_source_id(0, pos) == -1):
					var distance = min_distance_to_ladder(pos, tile_map)
					if (distance > 25):
						below_map.set_cell(0, pos, 0, Vector2i(0, TileType.LADDER_UP))
						set_air_around_tile(below_map, pos)
						tile_type = TileType.LADDER_DOWN
						tile_maps_ladder[tile_map][pos] = true
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
			tile_type = TileType.COAL
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

	print("zoom: %f, %f" % [zoom.x, zoom.y])

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
			if (tile_maps_chunks[visible_tile_map].has(chunk)):
				#print("skip %d, %d" % [chunk.x, chunk.y])
				continue
			tile_maps_chunks[visible_tile_map][chunk] = true
			for chunk_x in range(-HALF_CHUNK_SIZE, HALF_CHUNK_SIZE):
				for chunk_y in range(-HALF_CHUNK_SIZE, HALF_CHUNK_SIZE):
					generate_tile(visible_tile_map, Vector2i(x * CHUNK_SIZE + chunk_x, y * CHUNK_SIZE + chunk_y))
			#generate_tile(visible_tile_map, Vector2i(x, y))

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_Q:
				set_active_level(visible_level - 1)
			elif event.keycode == KEY_E:
				set_active_level(visible_level + 1)
