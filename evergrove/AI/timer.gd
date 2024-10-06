class_name AI_Timer extends Node

var time_between_ticks_in_seconds: float = 0.5
var timer: Timer = Timer.new()

func _ready() -> void:
	timer.wait_time = time_between_ticks_in_seconds
	timer.autostart = true # Starts the timer when added
	timer.one_shot = false # Keep repeating
	add_child(timer)
	timer.connect("timeout", _on_timer_timeout)
	print("AI timer ready")

func _on_timer_timeout() -> void:
	ai_globals.PROCESS_TICK.emit()
	print("AI tick")
