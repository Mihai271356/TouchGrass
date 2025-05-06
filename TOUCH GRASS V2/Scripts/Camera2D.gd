extends Camera2D

# Reference to the player
@export var player: NodePath  # Assign the Player node in the editor
var target: Node2D

func _ready():
	# Get the player node
	if player:
		target = get_node(player)
	# Ensure the camera is set to follow
	position_smoothing_enabled = true
	position_smoothing_speed = 5.0
	position.y = target.position.y + 325

func _process(delta):
	if target:
		# Follow the player only on the x-axis
		position.x = target.position.x
		# Keep the y-position fixed (no vertical movement)
		# position.y remains unchanged or set to a fixed value
		# Example: position.y = 0 (adjust based on your scene)
