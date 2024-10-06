extends Camera2D

# Bewegungsgeschwindigkeit der Kamera
var move_speed := 200.0
# Zoomgeschwindigkeit der Kamera
var zoom_speed := 0.1

func _process(delta):
	# Bewegung der Kamera mit WASD
	var direction := Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		direction.x += 1

	position += direction.normalized() * move_speed * delta

	# Zoomen der Kamera mit den Standardaktionen
	if Input.is_action_pressed("ui_page_up"):
		set_my_zoom(zoom.x - zoom_speed)
		#zoom -= Vector2(zoom_speed, zoom_speed)
	if Input.is_action_pressed("ui_page_down"):
		set_my_zoom(zoom.x + zoom_speed)
		#zoom += Vector2(zoom_speed, zoom_speed)

func _unhandled_input(event):
	# Zoomen der Kamera mit dem Mausrad
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			#zoom -= Vector2(zoom_speed, zoom_speed)
			set_my_zoom(zoom.x - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			#zoom += Vector2(zoom_speed, zoom_speed)
			set_my_zoom(zoom.x + zoom_speed)

	# Zoomen der Kamera mit dem Touchpad (MacOS)
	if event is InputEventPanGesture:
		#zoom += Vector2(event.delta.y * zoom_speed, event.delta.y * zoom_speed)
		set_my_zoom(zoom.x + (event.delta.y * zoom_speed))

		
func set_my_zoom(my_zoom: float):
	var curr_zoom = min(max(my_zoom, 0.5), 10.0)
	zoom = Vector2(curr_zoom, curr_zoom)
