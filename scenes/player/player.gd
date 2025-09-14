class_name Player
extends CharacterBody3D

enum State {IDLE, WALK, RUN, JUMP, CROUCHING, CROUCH_IDLE, CROUCH_WALK, AIM, SHOOT}

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


@export var blend_speed : float = 15.0

var default_fov : float
var is_aiming : bool = false
var current_sensitivity : float
var current_speed
var is_in_air : bool = false
var is_sprinting : bool = false

const BOB_FREQ = 2.0
const BOB_AMP = 0.04
var t_bob : float = 0.0

var current_state = State.IDLE

var walk_val = 0
var run_val = 0
var aim_val = 0
var shoot_val = 0
var jump_val = 0

@onready var camera: Camera3D = $Head/Camera
@onready var head: Node3D = $Head
@onready var model: Node3D = $Head/Camera/Weapons_Manager/Model

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_speed = speed
	default_fov = camera.fov
	current_sensitivity = sensitivity
	

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Rotate the ENTIRE player body for left-right (Yaw) movement.
		# This keeps the camera's pivot point at the center.
		self.rotate_y(-event.relative.x * sensitivity)

		# Rotate ONLY the camera for up-down (Pitch) movement.
		camera.rotate_x(-event.relative.y * sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-45), deg_to_rad(80))

		# Make sure the visual model matches the head's rotation.
		model.rotation.y = head.rotation.y

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

func handle_sprint() -> void:
	if Input.is_action_pressed("Sprint"):
		current_speed = sprint_speed
		is_sprinting = true
	else:
		current_speed = speed
		is_sprinting = false

func handle_ads(delta) -> void:
	# Hold to ADS
	is_aiming = Input.is_action_pressed("ADS")
	
	# Smooth FOV transition
	var target_fov = ads_fov if is_aiming else default_fov
	camera.fov = lerpf(camera.fov, target_fov, delta * ads_transition_speed)
	
	# Adjust sensitivity based on ADS state
	var target_sensitivity = sensitivity * ads_sensitivity_multiplier if is_aiming else sensitivity
	current_sensitivity = lerpf(current_sensitivity, target_sensitivity, delta * ads_transition_speed)
	
	current_state = State.AIM
	
func _physics_process(delta: float) -> void:
	handle_gravity(delta)
	handle_jump()
	handle_ads(delta)
	handle_movement(delta)
	head_bob(delta)
	move_and_slide()

# --- BULLETPROOF HEAD BOB ---
func head_bob(delta: float):
	var target_pos = Vector3.ZERO
	# Only apply bob if on the floor, moving, and not aiming.
	if is_on_floor() and velocity.length_squared() > 0.1 and not is_aiming:
		var bob_amp = BOB_AMP * (current_speed / speed) # Scale bob amplitude with speed
		t_bob += delta * BOB_FREQ * current_speed
		target_pos.y = sin(t_bob) * bob_amp

	# --- THE FIX ---
	# Apply the bob effect directly to the camera's local position, not the Head node.
	camera.position = camera.position.lerp(target_pos, delta * 10.0)


func handle_movement(delta) -> void:
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Back")
	var direction := (self.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Disable sprinting while aiming
	if direction and Input.is_action_pressed("Forward") and not is_aiming:
		handle_sprint()
	else:
		current_speed = speed
		is_sprinting = false
	
	if is_sprinting:
		current_state = State.RUN
	else:
		current_state = State.WALK
	
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
	
	#model.rotation.y = lerp_angle(model.rotation.y, head.rotation.y + PI, delta * 8.0)
