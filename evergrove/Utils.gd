enum BuildingType{
	BEER,
	ENERGY,
	FOOD,
}

const TILE_SIZE_HALF = 8
const TILE_SIZE = TILE_SIZE_HALF * 2

const LEVEL_DISTANCE = 100

enum WalkingDirection {
	FRONT,
	BACK,
	LEFT,
	RIGHT,
	DEFAULT,
}

enum Behaviour {
	IDLE,
	WALKING,
	SWIMMING,
	MINING,
	SLEEPING,
	EATING,
	DRINKING,
	BUILDING,
}

enum CursorType {
	SELECT,
	BUILD,
}

static func convert_to_v3(pos: Vector2i, level: int) -> Vector3i:
	return Vector3i(pos.x, pos.y, level)

static func convert_to_v3_astar(pos: Vector2i, level: int) -> Vector3i:
	return Vector3i(pos.x, pos.y, level * LEVEL_DISTANCE)

# returns null if param was null
static func convert_from_astar(vector: Vector3):
	if vector == null:
		return null
	return Vector3i(vector.x, vector.y, vector.z / LEVEL_DISTANCE)
