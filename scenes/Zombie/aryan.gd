extends CharacterBody3D

var Health = 100

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func Hit_Successful(Damage):
	Health -= Damage
	print("Target Health: " + str(Health))
	
	if Health <= 0:
		animation_player.play("Death")
		collision_shape.disabled = true
