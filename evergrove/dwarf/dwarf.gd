extends Node2D

var current_dungeon_layer

enum WalkingDirection {
	FRONT,
	BACK,
	LEFT,
	RIGHT
}

func _ready():
	# TODO retrieve walking direction and call play on animated sprite
	# this is just an example how to call animations
	var animated_sprite = self.get_child(1)
	animated_sprite.play("walk_front")
