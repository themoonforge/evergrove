extends Node2D

class_name World

const TILE_SIZE = 16
const HALF_CHUNK_SIZE = 16
const CHUNK_SIZE = HALF_CHUNK_SIZE * 2
const GLOBAL_SEED = 12345
const SCALE = 64.0
const ORE_SCALE = 32.0
const LAYERS = 5

enum TileType {
	AIR,	#0
	DIRT,	#1
	STONE,	#2
	COAL,	#3
	IRON,	#4
	COPPER,	#5
	SILVER,	#6
	GOLD,	#7
	GEM,	#8
	LADDER,	#9
	WATER,	#10
}

var terrain_noise: FastNoiseLite
var ore_noise: FastNoiseLite
var cave_noise: FastNoiseLite
var river_noise: FastNoiseLite

@onready var camera: Camera2D = $"../Camera2D"

@export var visible_tile_map: TileMap

@export var tile_maps = {}
@export var tile_type_to_id = {}
var tile_set: TileSet

@export var visible_rect: Rect2

func _ready():
	terrain_noise = FastNoiseLite.new()
	terrain_noise.seed = GLOBAL_SEED
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	terrain_noise.frequency = 1.0 / SCALE
	terrain_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	terrain_noise.fractal_octaves = 4
	terrain_noise.fractal_gain = 0.5
	terrain_noise.fractal_lacunarity = 2.0

	ore_noise = FastNoiseLite.new()
	ore_noise.seed = GLOBAL_SEED
	ore_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	ore_noise.frequency = 1.0 / ORE_SCALE
	ore_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	ore_noise.fractal_octaves = 4
	ore_noise.fractal_gain = 0.5
	ore_noise.fractal_lacunarity = 2.0

	cave_noise = FastNoiseLite.new()
	cave_noise.seed = GLOBAL_SEED + 1
	cave_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	cave_noise.frequency = 1.0 / SCALE
	cave_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	cave_noise.fractal_octaves = 4
	cave_noise.fractal_gain = 0.5
	cave_noise.fractal_lacunarity = 2.0

	river_noise = FastNoiseLite.new()
	river_noise.seed = GLOBAL_SEED + 2
	river_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	river_noise.frequency = 1.0 / SCALE
	river_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	river_noise.fractal_octaves = 4
	river_noise.fractal_gain = 0.5
	river_noise.fractal_lacunarity = 2.0

	tile_set = preload("res://tile_set.tres")
	for tile_type in TileType.values():
		var tile_id = tile_type  # Verwende die Position im Enum als Tile-ID
		tile_type_to_id[tile_type] = tile_id

	for layer in range(LAYERS):
		var tile_map = TileMap.new()
		tile_map.tile_set = tile_set
		tile_maps[layer] = tile_map
		add_child(tile_map)
		# Generiere initiale Chunks
		#generate_tile(tile_map, Vector2i(0, 0))
	set_active_level(0)
	
func set_active_level(level: int):
	visible_tile_map = tile_maps[level]
	for layer in tile_maps.keys():
		tile_maps[layer].visible = false
	visible_tile_map.visible = true
	check_visible_tiles(true)
	
func generate_tile(tile_map: TileMap, pos: Vector2i):
	if tile_map.get_cell_source_id(0, pos) != -1:
		return

	#var height = int(terrain_noise.get_noise_2d(global_x, global_y) * 10) + 10
	var tile_type = TileType.AIR
	var terrain_noise_value = terrain_noise.get_noise_2d(pos.x, pos.y)
	# Bestimme den Tile-Typ basierend auf verschiedenen Noise-Werten
	if terrain_noise_value < -0.75:
		tile_type = TileType.WATER
	elif terrain_noise_value < -0.55:
		tile_type = TileType.AIR
	else:
		tile_type = TileType.STONE
		var ore_value = ore_noise.get_noise_2d(pos.x, pos.y)
		if ore_value > 0.95:
			tile_type = TileType.GEM
		elif ore_value > 0.9:
			tile_type = TileType.STONE
		elif ore_value > 0.8:
			tile_type = TileType.GOLD
		elif ore_value > 0.78:
			tile_type = TileType.STONE
		elif ore_value > 0.7:
			tile_type = TileType.SILVER
		elif ore_value > 0.67:
			tile_type = TileType.STONE
		elif ore_value > 0.6:
			tile_type = TileType.COPPER
		elif ore_value > 0.56:
			tile_type = TileType.STONE
		elif ore_value > 0.5:
			tile_type = TileType.IRON
		elif ore_value > 0.4:
			tile_type = TileType.STONE
		elif ore_value > 0.25:
			tile_type = TileType.COAL
		elif ore_value > 0.2:
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
	var start_x = int(floor(visible_rect.position.x / (TILE_SIZE)))
	var start_y = int(floor(visible_rect.position.y / (TILE_SIZE)))
	var end_x = int(ceil((visible_rect.position.x + visible_rect.size.x) / (TILE_SIZE)))
	var end_y = int(ceil((visible_rect.position.y + visible_rect.size.y) / (TILE_SIZE)))

	# Überprüfe und generiere die Chunks für die sichtbaren Kacheln
	for x in range(start_x, end_x):
		for y in range(start_y, end_y):
			generate_tile(visible_tile_map, Vector2i(x, y))
