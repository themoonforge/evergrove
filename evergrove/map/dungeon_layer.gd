extends TileMap

class_name DungeonLayer

@onready var dwarf_container = $DwarfContainer
@onready var hub_container = $HubContainer

@export var level: int = 0

var terrain_noise: FastNoiseLite
var ore_noise: FastNoiseLite

@export var ladder: Dictionary = {}
@export var chunks: Dictionary = {}

@export var blocked_space = {}

const SCALE = 64.0
const ORE_SCALE = 32.0

func init(my_seed: int, my_level: int):
	terrain_noise = FastNoiseLite.new()
	terrain_noise.seed = my_seed
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	terrain_noise.frequency = 1.0 / SCALE
	terrain_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	terrain_noise.fractal_octaves = 4
	terrain_noise.fractal_gain = 0.5
	terrain_noise.fractal_lacunarity = 2.0

	ore_noise = FastNoiseLite.new()
	ore_noise.seed = my_seed + 1
	ore_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	ore_noise.frequency = 1.0 / ORE_SCALE
	ore_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	ore_noise.fractal_octaves = 4
	ore_noise.fractal_gain = 0.5
	ore_noise.fractal_lacunarity = 2.0

	level = my_level

	add_layer(1)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func distance_beween_tiles(pos1: Vector2i, pos2: Vector2i):
	return sqrt(pow(pos1.x - pos2.x, 2) + pow(pos1.y - pos2.y, 2))

func min_distance_to_ladder(pos: Vector2i):
	var min_distance = 1000000
	for ladder_pos in ladder.keys():
		var distance = distance_beween_tiles(pos, ladder_pos)
		if distance < min_distance:
			min_distance = distance
	return min_distance

func clear_fow(pos: Vector2i, radius: int):
	for x in range(-radius, radius):
		for y in range(-radius, radius):
			var tile_pos = Vector2i(pos.x + x, pos.y + y)
			erase_cell(1, tile_pos)
