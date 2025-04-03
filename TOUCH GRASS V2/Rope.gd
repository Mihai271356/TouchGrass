extends Node

var RopePiece = preload("res://rope_piece.tscn")

var piece_length := 1.0
var rope_close_tolerance := 40.0
var rope_parts := []

@onready var rope_start_piece = $RopeStartPiece
@onready var rope_end_piece = $Player

func _ready():
	# Debug to ensure nodes are found
	if rope_start_piece == null:
		print("Error: RopeStartPiece not found!")
	if rope_end_piece == null:
		print("Error: Player not found!")

func spawn_rope(start_pos: Vector2, end_pos: Vector2):
	rope_start_piece.global_position = start_pos
	rope_end_piece.global_position = end_pos
	
	# Ensure the C/J nodes exist
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
