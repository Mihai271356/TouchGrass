extends Area2D

var grav: float = 980.0  # Gravity strength (pixels per second squared, similar to real-world 9.8 m/s^2 scaled)
var velocity: Vector2 = Vector2.ZERO  # Velocity to track movement

func _ready():
	# Ensure the node is in the "rope_cutters" group (can also be set in the editor)
	add_to_group("rope_cutters")

func _physics_process(delta: float) -> void:
	# Apply gravity to the velocity (only in the y-direction for downward force)
	velocity.y += grav * delta
	
	# Update the position based on velocity
	position += velocity * delta
	
	# Optional: Add a ground check or reset velocity if needed
	# Example: Stop falling at y = 600
