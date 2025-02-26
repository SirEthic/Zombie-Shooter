class_name Player
extends CharacterBody3D

@export var jump_velocity : float
@export var sensitivity : float
@export var speed : float
@export var sprint_speed : float

var current_speed

var is_in_air : bool = false

@onready var camera: Camera3D = $Head/Camera
@onready var head: Node3D = $Head

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_speed = speed

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * sensitivity)
		camera.rotate_x(-event.relative.y * sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(60))

func handle_gravity(delta) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		is_in_air = true
	
	if is_in_air:
		apply_landing_effect()
		is_in_air = false

func apply_landing_effect() -> void:
	var impact_strength = abs(velocity.y) / 10.0
	impact_strength = clamp(impact_strength, 0.05, 0.1)
	
	if camera.has_method("apply_landing_effect"):
		camera.apply_landing_effect(impact_strength)

func handle_jump() -> void:
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = jump_velocity
		is_in_air = true

func handle_sprint() -> void:
	if Input.is_action_pressed("Sprint"):
		current_speed = sprint_speed
	else:
		current_speed = speed

func _physics_process(delta: float) -> void:
	handle_gravity(delta)
	handle_jump()
	handle_input(delta)
	move_and_slide()

func handle_input(delta) -> void:
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Back")
	var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction and Input.is_action_pressed("Forward"):
		handle_sprint()
	else:
		current_speed = speed
	
	if direction:
		velocity.x = lerpf(velocity.x, direction.x * current_speed, delta * 8)
		velocity.z = lerpf(velocity.z, direction.z * current_speed, delta * 8)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
