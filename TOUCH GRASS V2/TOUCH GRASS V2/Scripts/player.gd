extends RigidBody2D

# Movement properties
var speed: float = 300  # Speed of movement (pixels per second)
var velocity: Vector2 = Vector2.ZERO  # Current velocity of the object
var velocity_retention: float = 0  # How much past velocity is retained (0 = none, 1 = full)

# Tug calculation properties
var rope_stiffness: float = 100.0  # Stiffness constant for calculating tug (adjust as needed)
var parent: Object = null  # Reference to the rope (set by the rope script)

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
	
	# Print the player's speed
	var player_speed: float = linear_velocity.length()
	print("Player speed: ", player_speed, " pixels/second")
	
	# Calculate and print the tug on the rope
	var tug: float = calculate_tug()
	print("Tug on rope: ", tug, " N")

func calculate_tug() -> float:
	if parent == null or parent.rope_parts.is_empty():
		return 0.0
	
	# Get the last rope piece and its joint position
	var last_piece = parent.rope_parts[-1]
	var last_joint_pos = last_piece.get_node("C/J").global_position
	
	# Get the player's joint position
	var player_joint = get_node("C/J")
	if player_joint == null:
		return 0.0
	var player_joint_pos = player_joint.global_position
	
	# Calculate the distance between the player and the last rope piece
	var distance = player_joint_pos.distance_to(last_joint_pos)
	
	# Calculate the stretch (difference from the rest length)
	var rest_length = parent.piece_length  # Assuming piece_length is the rest length between joints
	var stretch = distance - rest_length
	
	# Calculate the tug using Hooke's Law: force = stiffness * stretch
	var tug = rope_stiffness * stretch
	return max(tug, 0.0)  # Ensure tug is non-negative
