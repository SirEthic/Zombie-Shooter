class_name Character
extends CharacterBody3D

const GRAVITY := 9.8

@export var can_respawn : bool

@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer

enum State {IDLE, WALK, RUN, JUMP, CROUCHING, CROUCH_IDLE, CROUCH_WALK, AIM, SHOOT}

var anim_map : Dictionary = {
	State.IDLE : "Idle",
	State.WALK : "Walk",
	State.RUN : "Run",
	State.JUMP : "Idle",
	State.CROUCHING : "Crouch",
	State.CROUCH_IDLE : "Crouch_Idle",
	State.CROUCH_WALK : "Crouch_Walk",
	State.AIM : "Aim",
	State.SHOOT : "Shoot",
}

var current_state = State.IDLE

func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	handle_animations()
	pass

func gravity(delta) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

func handle_input(_delta) -> void:
	pass

func handle_animations() -> void:
	var target_animation = anim_map[current_state]
	
	if animation_player.has_animation(target_animation):
		if animation_player.current_animation != target_animation:
			animation_player.play(target_animation, 0.25)
