extends Camera3D

@export var bob_frequency: float = 2.0
@export var bob_amplitude: float = 0.08
@export var bob_horizontal_factor: float = 0.6
@export var min_speed_threshold: float = 0.1
@export var transition_speed: float = 10.0  # Increased for faster response

# Variables to track head bob state
var default_position: Vector3
var time_passed: float = 0.0
var current_bob_amplitude: float = 0.0
var last_bob_position: Vector3 = Vector3.ZERO

# Reference to the player's character body
@onready var player: Player = $"../.."

func _ready():
	# Store the camera's default position
	default_position = position
	last_bob_position = default_position

func _process(delta):
	if player == null:
		return
		
	# Check if player is moving on the ground
	var is_moving = player.velocity.length() > min_speed_threshold
	var is_on_ground = player.is_on_floor()
	
	# Determine if we should be bobbing
	var is_bobbing = is_moving and is_on_ground
	
	# Calculate target position
	var target_position = default_position
	
	if is_bobbing:
		# Smoothly increase bob amplitude when moving
		current_bob_amplitude = move_toward(current_bob_amplitude, bob_amplitude, delta * transition_speed)
		
		# Calculate movement speed for bob timing
		var speed_factor = clamp(player.velocity.length() / 5.0, 0.5, 2.0)
		time_passed += delta * bob_frequency * speed_factor
		
		# Calculate bob offsets
		var vertical_offset = sin(time_passed * PI) * current_bob_amplitude
		var horizontal_offset = cos(time_passed * PI * 0.5) * current_bob_amplitude * bob_horizontal_factor
		
		# Apply the bob to the target position
		target_position += Vector3(horizontal_offset, vertical_offset, 0)
	else:
		# Smoothly decrease bob amplitude when not moving
		current_bob_amplitude = move_toward(current_bob_amplitude, 0.0, delta * transition_speed)
		
		# If we still have some amplitude, continue the bob animation
		if current_bob_amplitude > 0.001:
			time_passed += delta * bob_frequency
			
			var vertical_offset = sin(time_passed * PI) * current_bob_amplitude
			var horizontal_offset = cos(time_passed * PI * 0.5) * current_bob_amplitude * bob_horizontal_factor
			
			target_position += Vector3(horizontal_offset, vertical_offset, 0)
	
	# Apply a strong but not instant movement toward the target position
	# Use a higher lerp factor to make it more responsive while still smooth
	position = position.lerp(target_position, delta * 20.0)  # Higher value = faster movement
	last_bob_position = position

# Landing effect
func apply_landing_effect(impact_strength: float = 1.0):
	# Calculate impact and apply it directly
	var impact = -bob_amplitude * 3.0 * impact_strength
	position.y = position.y + impact  # Apply relative to current position
