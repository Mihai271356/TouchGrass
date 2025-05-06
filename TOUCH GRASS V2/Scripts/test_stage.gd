extends Node2D

var Rope = preload(("res://Scripts/rope.tscn"))

var start_pos := Vector2.ZERO
var end_pos := Vector2.ZERO

func _ready():
			var rope = Rope.instantiate()
			add_child(rope)
			rope.spawn_rope(Vector2(-50,350), Vector2(700,350))
			start_pos = Vector2.ZERO
			end_pos = Vector2.ZERO
			print(rope.rope_parts)
