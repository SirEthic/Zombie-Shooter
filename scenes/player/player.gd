class_name Player
extends Character

@export var jump_velocity : float
@export var sensitivity : float
@export var speed : float
@export var sprint_speed : float

@export var ads_fov : float = 45.0
@export var ads_sensitivity_multiplier : float = 0.5
@export var ads_transition_speed : float = 8.0

@export var acceleration : float = 10.0
@export var friction : float = 20.0
@export var air_acceleration : float = 2.0
@export var air_friction : float = 0.5

var default_fov : float
var is_aiming : bool = false
var current_sensitivity : float
var current_speed
var is_in_air : bool = false
var is_sprinting : bool = false

const BOB_FREQ  : float = 2.4
const BOB_AMP : float = 0.05
const BOB_SMOOTH : float = 8.0
var t_bob : float = 0.0
var current_bob_amount : float = 0.0
var bob_offset : Vector3 = Vector3.ZERO

@onready var camera: Camera3D = $Head/Camera
@onready var head: Node3D = $Head
@onready var model: Node3D = $Model

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_speed = speed
	default_fov = camera.fov
	current_sensitivity = sensitivity

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Use current_sensitivity instead of sensitivity
		head.rotate_y(-event.relative.x * current_sensitivity)
		model.rotation.y = head.rotation.y + PI
		camera.rotate_x(-event.relative.y * current_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func handle_gravity(delta) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		is_in_air = true
	elif is_in_air:
		is_in_air = false

func handle_jump() -> void:
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = jump_velocity
		is_in_air = true
		current_state = State.JUMP

func handle_sprint(delta) -> void:
	if Input.is_action_just_pressed("Sprint"):
		is_sprinting = !is_sprinting
		current_speed = sprint_speed if is_sprinting else speed

	
	if is_sprinting:
		current_state = State.RUN
		animation_player.speed_scale = 1.0
		head_bob(delta)
	else:
		current_state = State.WALK
		animation_player.speed_scale = 0.95
	

func handle_ads(delta) -> void:
	# Hold to ADS
	is_aiming = Input.is_action_pressed("ADS")
	
	# Smooth FOV transition
	var target_fov = ads_fov if is_aiming else default_fov
	camera.fov = lerpf(camera.fov, target_fov, delta * ads_transition_speed)
	
	# Adjust sensitivity based on ADS state
	var target_sensitivity = sensitivity * ads_sensitivity_multiplier if is_aiming else sensitivity
	current_sensitivity = lerpf(current_sensitivity, target_sensitivity, delta * ads_transition_speed)

func _physics_process(delta: float) -> void:
	handle_gravity(delta)
	handle_jump()
	handle_ads(delta)
	handle_movement(delta)
	handle_animations()
	move_and_slide()

func head_bob(delta) -> void:
	# Calculate horizontal velocity for bob amount
	var horizontal_velocity = Vector2(velocity.x, velocity.z).length()
	
	# Normalize bob amount based on movement speed
	var target_bob = horizontal_velocity / speed
	target_bob = clamp(target_bob, 0.0, 1.0)
	
	# Reduce bob when aiming or in air
	if is_aiming:
		target_bob *= 0.3
	if not is_on_floor():
		target_bob = 0.0
	
	current_bob_amount = lerpf(current_bob_amount, target_bob, delta * BOB_SMOOTH)
	
	if current_bob_amount > 0.01:
		t_bob += delta * BOB_FREQ * horizontal_velocity
	
	# Calculate bob offset instead of directly modifying camera position
	bob_offset = Vector3.ZERO
	bob_offset.y = sin(t_bob) * BOB_AMP * current_bob_amount
	bob_offset.x = sin(t_bob * 0.5) * BOB_AMP * 0.5 * current_bob_amount
	
	# Apply bob offset smoothly
	camera.position = camera.position.lerp(bob_offset, delta * 10.0)

func handle_movement(delta) -> void:
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Back")
	var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Disable sprinting while aiming
	if direction and Input.is_action_pressed("Forward") and not is_aiming:
		handle_sprint(delta)
	else:
		current_speed = speed
		is_sprinting = false

	var movement_speed = current_speed * 0.6 if is_aiming else current_speed

	var current_acceleration = acceleration if is_on_floor() else air_acceleration
	var current_friction = friction if is_on_floor() else air_friction

	var target_velocity = direction * movement_speed

	if direction.length() > 0:
		velocity.x = lerpf(velocity.x, target_velocity.x, delta * current_acceleration)
		velocity.z = lerpf(velocity.z, target_velocity.z, delta * current_acceleration)
		
	else:
		velocity.x = lerpf(velocity.x, 0, delta * current_friction)
		velocity.z = lerpf(velocity.z, 0, delta * current_friction)

		if velocity.length() < 0.1:
			velocity.x = 0
			velocity.z = 0
		
		current_state = State.IDLE
