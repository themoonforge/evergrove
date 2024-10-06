enum BuildingType{
	BEER,
	ENERGY,
	FOOD,
}

const TILE_SIZE_HALF = 8
const TILE_SIZE = TILE_SIZE_HALF * 2

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
