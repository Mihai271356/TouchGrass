extends Control

func _ready():
	$Button.pressed.connect(_on_restart_pressed)
	$Button.grab_focus()

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Main.tscn")
	queue_free()
