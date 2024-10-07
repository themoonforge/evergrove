extends CanvasLayer

@onready var text_input: LineEdit = $"./VFlowContainer/VFlowContainer/SeedInput"
@onready var background: TileMap = $"../TileMap"

@export var seed: int = 0

const min_seed = 0
const max_seed = 1000000

func set_seed(value: int):
	seed = value
	if text_input.text != str(seed):
		text_input.text = str(seed)

# Called when the node enters the scene tree for the first time.
func _ready():
	set_seed(12345)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_random_button_pressed() -> void:
	set_seed(randi_range(0, max_seed))

func _on_seed_input_text_changed(new_text: String) -> void:
	set_seed(max(min(int(new_text), max_seed), min_seed))

func _on_start_button_pressed() -> void:
	Globals.seed = seed
	get_tree().change_scene_to_file("res://world.tscn")
