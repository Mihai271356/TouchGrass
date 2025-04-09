extends Node

var RopePiece = preload("res://Scripts/rope_piece.tscn")
var RopeCutter = preload("res://Scripts/virus.tscn")  # Preload the RopeCutter scene

var piece_length := 1.0
var rope_close_tolerance := 40.0
var rope_parts := []

# Force to apply when pulling the player back
var pull_force := 500.0

@onready var rope_start_piece = $RopeStartPiece
@onready var rope_end_piece = $Player

func _ready():
	if rope_start_piece == null:
		print("Error: RopeStartPiece not found!")
	if rope_end_piece == null:
		print("Error: Player not found!")
	
	# Spawn a RopeCutter for testing (you can also add this in the editor)
	var cutter = RopeCutter.instantiate()
	cutter.position = Vector2(400, 600)  # Position the cutter somewhere in the scene
	add_child(cutter)
	
	# Connect the body_entered signal to detect rope collisions, binding the cutter instance
	cutter.connect("body_entered", Callable(self, "_on_rope_cutter_body_entered").bind(cutter))

func _input(event):
	# Extend the rope on right-click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		extend_rope()
	
	# Shorten the rope on "R" key press
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		shorten_rope()

func spawn_rope(start_pos: Vector2, end_pos: Vector2):
	rope_start_piece.global_position = start_pos
	rope_end_piece.global_position = end_pos
	
	var start_joint = rope_start_piece.get_node("C/J")
	var end_joint = rope_end_piece.get_node("C/J")
	if start_joint == null or end_joint == null:
		print("Error: C/J node missing in RopeStartPiece or Player!")
		return
	
	var distance = start_pos.distance_to(end_pos)
	var pieces_amount = distance / piece_length
	
	var spawn_angle = (end_pos - start_pos).angle() - PI/2
	
	create_rope(pieces_amount, rope_start_piece, end_pos, spawn_angle)

func create_rope(pieces_amount: int, parent: Object, end_pos: Vector2, spawn_angle: float) -> void:
	for i in pieces_amount:
		parent = add_piece(parent, i, spawn_angle)
		parent.set_name("rope_piece_" + str(i))
		rope_parts.append(parent)
		
		var joint_pos = parent.get_node("C/J").global_position
		if joint_pos.distance_to(end_pos) < rope_close_tolerance:
			break
	
	# Connect the last rope piece to the player
	var end_joint = rope_end_piece.get_node("C/J")
	end_joint.node_a = rope_end_piece.get_path()
	end_joint.node_b = rope_parts[-1].get_path()

func add_piece(parent: Object, id: int, spawn_angle: float) -> Object:
	var joint: PinJoint2D = parent.get_node("C/J") as PinJoint2D
	var piece: Object = RopePiece.instantiate() as Object
	piece.global_position = joint.global_position
	piece.rotation = spawn_angle
	piece.parent = self
	piece.id = id
	add_child(piece)
	joint.node_a = parent.get_path()
	joint.node_b = piece.get_path()
	
	return piece

func extend_rope():
	if rope_parts.is_empty():
		return
	
	# Get the last rope piece and its joint
	var last_piece = rope_parts[-1]
	var last_joint = last_piece.get_node("C/J") as PinJoint2D
	
	# Calculate the spawn angle based on the direction from the last piece to the player
	var spawn_angle = (rope_end_piece.global_position - last_piece.global_position).angle() - PI/2
	
	# Add a new piece
	var new_piece = add_piece(last_piece, rope_parts.size(), spawn_angle)
	new_piece.set_name("rope_piece_" + str(rope_parts.size()))
	rope_parts.append(new_piece)
	
	# Disconnect the player from the previous last piece
	var end_joint = rope_end_piece.get_node("C/J") as PinJoint2D
	end_joint.node_b = ""
	
	# Connect the player to the new piece
	var new_joint = new_piece.get_node("C/J") as PinJoint2D
	end_joint.node_a = rope_end_piece.get_path()
	end_joint.node_b = new_piece.get_path()

func shorten_rope():
	if rope_parts.size() <= 1:  # Don't remove the last piece to avoid breaking the rope
		return
	
	# Get the last rope piece
	var last_piece = rope_parts[-1]
	
	# Disconnect the player from the last piece
	var end_joint = rope_end_piece.get_node("C/J") as PinJoint2D
	end_joint.node_b = ""
	
	# Remove the last piece from the array and the scene
	rope_parts.pop_back()
	last_piece.queue_free()
	
	# Connect the player to the new last piece (if there are still pieces left)
	var new_connection_point: Node
	if not rope_parts.is_empty():
		var new_last_piece = rope_parts[-1]
		var new_last_joint = new_last_piece.get_node("C/J") as PinJoint2D
		end_joint.node_a = rope_end_piece.get_path()
		end_joint.node_b = new_last_piece.get_path()
		new_connection_point = new_last_piece
	else:
		# If no pieces are left, connect the player directly to the start piece
		var start_joint = rope_start_piece.get_node("C/J") as PinJoint2D
		end_joint.node_a = rope_end_piece.get_path()
		end_joint.node_b = rope_start_piece.get_path()
		new_connection_point = rope_start_piece
	
	# Apply a force to pull the player toward the new connection point
	if rope_end_piece is RigidBody2D:
		var direction = (new_connection_point.global_position - rope_end_piece.global_position).normalized()
		rope_end_piece.apply_central_impulse(direction * pull_force)

# Called when a body enters the RopeCutter's Area2D
# The cutter parameter is the RopeCutter instance that emitted the signal
func _on_rope_cutter_body_entered(body: Node, cutter: Area2D) -> void:
	# Check if the body is a rope piece
	if body in rope_parts:
		var piece_index = rope_parts.find(body)
		if piece_index != -1:
			break_rope_at(piece_index)
			# Remove the RopeCutter after breaking the rope
			cutter.queue_free()

# Break the rope at the specified piece index by removing the piece and splitting the rope
func break_rope_at(piece_index: int) -> void:
	if piece_index < 0 or piece_index >= rope_parts.size():
		return
	
	# Get the piece to remove
	var piece_to_remove = rope_parts[piece_index]
	
	# Disconnect the piece from its neighbors
	if piece_index > 0:
		var prev_piece = rope_parts[piece_index - 1]
		var prev_joint = prev_piece.get_node("C/J") as PinJoint2D
		prev_joint.node_b = ""  # Disconnect from the piece being removed
	else:
		# If it's the first piece, disconnect from the start piece
		var start_joint = rope_start_piece.get_node("C/J") as PinJoint2D
		start_joint.node_b = ""
	
	if piece_index < rope_parts.size() - 1:
		var next_piece = rope_parts[piece_index + 1]
		var next_joint = next_piece.get_node("C/J") as PinJoint2D
		next_joint.node_a = ""  # Disconnect from the piece being removed
	else:
		# If it's the last piece, disconnect from the player
		var end_joint = rope_end_piece.get_node("C/J") as PinJoint2D
		end_joint.node_b = ""
	
	# Remove the piece from the array and the scene
	rope_parts.remove_at(piece_index)
	piece_to_remove.queue_free()
	
	# Split the rope into two segments
	# First segment: pieces before the removed piece (0 to piece_index - 1)
	# Second segment: pieces after the removed piece (piece_index to end)
	
	# Ensure the first segment remains connected
	if piece_index > 0:
		# The pieces before the removed piece should already be connected to each other
		# Just ensure the last piece of the first segment is connected to the start piece
		var last_piece_of_first_segment = rope_parts[piece_index - 1]
		var start_joint = rope_start_piece.get_node("C/J") as PinJoint2D
		# The connection should already exist from the initial setup, so we don't need to change it
	else:
		# If the removed piece was the first piece, the first segment is empty
		pass
	
	# Ensure the second segment remains connected to the player
	if piece_index < rope_parts.size():
		# Reconnect the pieces in the second segment to each other
		for i in range(piece_index, rope_parts.size() - 1):
			var current_piece = rope_parts[i]
			var next_piece = rope_parts[i + 1]
			var current_joint = current_piece.get_node("C/J") as PinJoint2D
			current_joint.node_a = current_piece.get_path()
			current_joint.node_b = next_piece.get_path()
		
		# Connect the first piece of the second segment to the player
		var first_piece_of_second_segment = rope_parts[piece_index]
		var first_piece_joint = first_piece_of_second_segment.get_node("C/J") as PinJoint2D
		var end_joint = rope_end_piece.get_node("C/J") as PinJoint2D
		
		# Ensure the first piece's joint is properly set up
		if piece_index < rope_parts.size() - 1:
			# If there are more pieces after this one, the joint should already be set to connect to the next piece
			pass
		else:
			# If this is the last piece, clear its node_b to avoid connecting to a non-existent piece
			first_piece_joint.node_b = ""
		
		# Connect the player's joint to the first piece of the second segment
		end_joint.node_a = rope_end_piece.get_path()
		end_joint.node_b = first_piece_of_second_segment.get_path()
	else:
		# If no pieces remain after the removed piece, connect the player directly to the start piece
		var end_joint = rope_end_piece.get_node("C/J") as PinJoint2D
		var start_joint = rope_start_piece.get_node("C/J") as PinJoint2D
		end_joint.node_a = rope_end_piece.get_path()
		end_joint.node_b = rope_start_piece.get_path()
	
	# Do NOT apply any additional forces to avoid jumping
	# The physics engine will handle the natural behavior of the split segments
