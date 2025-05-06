extends Node

var RopePiece = preload("res://Scripts/rope_piece.tscn")
var RopeCutter = preload("res://Scripts/virus.tscn")

var piece_length := 1.0
var rope_close_tolerance := 40.0
var rope_parts := []
var is_rope_broken := false

var pull_force := 500.0

@onready var rope_start_piece = $RopeStartPiece
@onready var rope_end_piece = $Player

func _ready():
	if rope_start_piece == null:
		print("Error: RopeStartPiece not found!")
	if rope_end_piece == null:
		print("Error: Player not found!")
	
	var cutters = get_tree().get_nodes_in_group("rope_cutters")
	print("Found RopeCutters:", cutters.size())
	for cutter in cutters:
		print(" - ", cutter.name)
		if cutter is Area2D:
			cutter.connect("body_entered", Callable(self, "_on_rope_cutter_body_entered").bind(cutter))

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		extend_rope()
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		shorten_rope()

#func _physics_process(delta):
	#print("", is_rope_broken)

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
	
	var last_piece = rope_parts[-1]
	var last_joint = last_piece.get_node("C/J") as PinJoint2D
	var spawn_angle = (rope_end_piece.global_position - last_piece.global_position).angle() - PI/2
	var new_piece = add_piece(last_piece, rope_parts.size(), spawn_angle)
	new_piece.set_name("rope_piece_" + str(rope_parts.size()))
	rope_parts.append(new_piece)
	
	var end_joint = rope_end_piece.get_node("C/J") as PinJoint2D
	end_joint.node_b = ""
	var new_joint = new_piece.get_node("C/J") as PinJoint2D
	end_joint.node_a = rope_end_piece.get_path()
	end_joint.node_b = new_piece.get_path()

func shorten_rope():
	if rope_parts.size() <= 1:
		return
	
	var last_piece = rope_parts[-1]
	var end_joint = rope_end_piece.get_node("C/J") as PinJoint2D
	end_joint.node_b = ""
	rope_parts.pop_back()
	last_piece.queue_free()
	
	var new_connection_point: Node
	if not rope_parts.is_empty():
		var new_last_piece = rope_parts[-1]
		var new_last_joint = new_last_piece.get_node("C/J") as PinJoint2D
		end_joint.node_a = rope_end_piece.get_path()
		end_joint.node_b = new_last_piece.get_path()
		new_connection_point = new_last_piece
	else:
		var start_joint = rope_start_piece.get_node("C/J") as PinJoint2D
		end_joint.node_a = rope_end_piece.get_path()
		end_joint.node_b = rope_start_piece.get_path()
		new_connection_point = rope_start_piece
	
	if rope_end_piece is RigidBody2D:
		var direction = (new_connection_point.global_position - rope_end_piece.global_position).normalized()
		rope_end_piece.apply_central_impulse(direction * pull_force)

func _on_rope_cutter_body_entered(body: Node, cutter: Area2D) -> void:
	if body in rope_parts:
		var piece_index = rope_parts.find(body)
		if piece_index != -1:
			break_rope_at(piece_index)
			cutter.queue_free()

func break_rope_at(piece_index: int) -> void:
	if piece_index < 0 or piece_index >= rope_parts.size():
		return
	
	var piece_to_remove = rope_parts[piece_index]
	
	if piece_index > 0:
		var prev_piece = rope_parts[piece_index - 1]
		var prev_joint = prev_piece.get_node("C/J") as PinJoint2D
		prev_joint.node_b = ""
	else:
		var start_joint = rope_start_piece.get_node("C/J") as PinJoint2D
		start_joint.node_b = ""
	
	if piece_index < rope_parts.size() - 1:
		var next_piece = rope_parts[piece_index + 1]
		var next_joint = next_piece.get_node("C/J") as PinJoint2D
		next_joint.node_a = ""
	else:
		var end_joint = rope_end_piece.get_node("C/J") as PinJoint2D
		end_joint.node_b = ""
	
	rope_parts.remove_at(piece_index)
	piece_to_remove.queue_free()
	
	is_rope_broken = true
	
	if piece_index > 0:
		var last_piece_of_first_segment = rope_parts[piece_index - 1]
		var start_joint = rope_start_piece.get_node("C/J") as PinJoint2D
	
	if piece_index < rope_parts.size():
		for i in range(piece_index, rope_parts.size() - 1):
			var current_piece = rope_parts[i]
			var next_piece = rope_parts[i + 1]
			var current_joint = current_piece.get_node("C/J") as PinJoint2D
			current_joint.node_a = current_piece.get_path()
			current_joint.node_b = next_piece.get_path()
		
		var first_piece_of_second_segment = rope_parts[piece_index]
		var first_piece_joint = first_piece_of_second_segment.get_node("C/J") as PinJoint2D
		var end_joint = rope_end_piece.get_node("C/J") as PinJoint2D
		
		if piece_index < rope_parts.size() - 1:
			pass
		else:
			first_piece_joint.node_b = ""
		
		end_joint.node_a = rope_end_piece.get_path()
		end_joint.node_b = first_piece_of_second_segment.get_path()
	else:
		var end_joint = rope_end_piece.get_node("C/J") as PinJoint2D
		var start_joint = rope_start_piece.get_node("C/J") as PinJoint2D
		end_joint.node_a = rope_end_piece.get_path()
		end_joint.node_b = rope_start_piece.get_path()
