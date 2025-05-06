extends Node2D

var Rope = preload(("res://Scripts/rope.tscn"))

var start_pos := Vector2.ZERO
var end_pos := Vector2.ZERO

func _ready():
			var rope = Rope.instantiate()
			add_child(rope)
			rope.spawn_rope(Vector2(500,500), Vector2(100,100))
			start_pos = Vector2.ZERO
			end_pos = Vector2.ZERO
			print(rope.rope_parts)
