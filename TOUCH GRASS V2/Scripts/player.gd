extends RigidBody2D

var speed: float = 300
var velocity: Vector2 = Vector2.ZERO
var velocity_retention: float = 0

var rope_stiffness: float = 100.0
var parent: Object = null
var gravity_lever_active: bool = false
var custom_gravity: float = 200.0
var health: float = 100.0

@export var rope_node: Node = null
@onready var death_screen_scene = preload("res://DeathScreen.tscn")

func _ready():
	var pickup_sensor = $PickupSensor
	if pickup_sensor:
		pickup_sensor.area_entered.connect(_on_pickup_sensor_area_entered)
		pickup_sensor.area_entered.connect(_on_gravity_lever_entered)
		pickup_sensor.area_entered.connect(_on_hazard_entered)

func _on_pickup_sensor_area_entered(area: Area2D) -> void:
	if area.is_in_group("Pickups"):
		for i in range(50):
			var event = InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_RIGHT
			event.pressed = true
			event.position = get_global_mouse_position()
			Input.parse_input_event(event)
		area.queue_free()
		print("Picked up:", area.name)

func _on_gravity_lever_entered(area: Area2D) -> void:
	if area.is_in_group("gravity_levers"):
		gravity_lever_active = true
		print("Gravity lever touched:", area.name)
		await get_tree().create_timer(3.0).timeout
		gravity_lever_active = false
		print("Gravity lever effect ended")

func _on_hazard_entered(area: Area2D) -> void:
	if area.is_in_group("Hazards"):
		health -= 50.0
		print("Hit hazard:", area.name, " Health:", health)
		if health <= 0:
			die()

func die() -> void:
	var death_screen = death_screen_scene.instantiate()
	get_tree().root.add_child(death_screen)
	get_tree().paused = true
	queue_free()  # Remove player from scene

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_position: Vector2 = get_global_mouse_position()
		var direction: Vector2 = (click_position - global_position).normalized()
		var new_velocity: Vector2 = direction * speed
		velocity = velocity * velocity_retention + new_velocity * (1 - velocity_retention)

func _physics_process(delta: float) -> void:
	if velocity != Vector2.ZERO:
		linear_velocity = velocity
		velocity = Vector2.ZERO
	
	if gravity_lever_active:
		apply_force(Vector2(0, custom_gravity * mass))
	
	var player_speed: float = linear_velocity.length()
	# print("Player speed: ", player_speed, " pixels/second")
	var tug: float = calculate_tug()
	# print("Tug on rope: ", tug, " N")

func calculate_tug() -> float:
	if parent == null or parent.rope_parts.is_empty():
		return 0.0
	var last_piece = parent.rope_parts[-1]
	var last_joint_pos = last_piece.get_node("C/J").global_position
	var player_joint = get_node("C/J")
	if player_joint == null:
		return 0.0
	var player_joint_pos = player_joint.global_position
	var distance = player_joint_pos.distance_to(last_joint_pos)
	var rest_length = parent.piece_length
	var stretch = distance - rest_length
	var tug = rope_stiffness * stretch
	return max(tug, 0.0)
