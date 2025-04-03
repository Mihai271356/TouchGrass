extends RigidBody2D

# Movement properties
var speed: float = 300  # Speed of movement (pixels per second)
var velocity: Vector2 = Vector2.ZERO  # Current velocity of the object
var velocity_retention: float = 0  # How much past velocity is retained (0 = none, 1 = full)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Calculate direction to the mouse click
		var click_position: Vector2 = get_global_mouse_position()
		var direction: Vector2 = (click_position - global_position).normalized()
		
		# Blend the new direction with the past velocity
		var new_velocity: Vector2 = direction * speed
		velocity = velocity * velocity_retention + new_velocity * (1 - velocity_retention)

func _physics_process(delta: float) -> void:
	# Apply the velocity to the RigidBody2D
	if velocity != Vector2.ZERO:
		# Reset linear velocity to ensure smooth movement
		linear_velocity = velocity
		velocity = Vector2.ZERO
