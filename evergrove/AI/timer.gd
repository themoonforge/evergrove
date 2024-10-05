class_name AI_Timer extends Node

var time_between_ticks_in_seconds: float = 5.0
var timer: Timer

func _ready() -> void:
    timer.wait_time = time_between_ticks_in_seconds
    timer.autostart = true # Starts the timer when added
    timer.one_shot = false # Keep repeating
    connect("PROCESS_TICK", _on_timer_timeout)

func _on_timer_timeout() -> void:
    emit_signal("PROCESS_TICK")
    print("Timer triggered!")