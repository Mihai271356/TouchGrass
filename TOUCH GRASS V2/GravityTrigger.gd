extends Area2D

var gravity_timer: Timer = null
var default_gravity: float = 0.0
var active_gravity: float = 980.0

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	
	# Save the default gravity (currently 0)
	default_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	
	# Create a timer for 3 seconds
	gravity_timer = Timer.new()
	gravity_timer.wait_time = 3.0
	gravity_timer.one_shot = true
	gravity_timer.connect("timeout", Callable(self, "_on_gravity_timer_timeout"))
	add_child(gravity_timer)

func _on_body_entered(body: Node) -> void:
	if not gravity_timer.is_stopped():
		return
	
	# Activate gravity
	ProjectSettings.set_setting("physics/2d/default_gravity", active_gravity)
	print("Gravity activated:", active_gravity)
	gravity_timer.start()

func _on_gravity_timer_timeout() -> void:
	# Deactivate gravity
	ProjectSettings.set_setting("physics/2d/default_gravity", default_gravity)
	print("Gravity deactivated:", default_gravity)
