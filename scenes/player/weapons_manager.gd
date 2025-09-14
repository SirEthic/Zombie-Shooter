extends Node3D

signal Weapon_Changed
signal Update_Ammo
signal Update_Weapon_Stack

@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer
@onready var bullet_point: Marker3D = $Model/Bullet_Point

var Debug_Bullet = preload("res://scenes/Bullet/hit_debug.tscn")

var current_weapon = null

var weapon_stack = []

var weapon_indicator = 0

var next_weapon: String

var weapon_list = {}

@export var _weapon_resources: Array[WeaponResource]

@export var start_weapons: Array[String]

enum {NULL, HITSCAN, PROJECTILE}

func _ready() -> void:
	Initialize(start_weapons)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("WeaponUp"):
		weapon_indicator = min(weapon_indicator+1, weapon_stack.size()-1)
		exit(weapon_stack[weapon_indicator])
	
	if event.is_action_pressed("WeaponDown"):
		weapon_indicator = max(weapon_indicator-1, 0)
		exit(weapon_stack[weapon_indicator])
	
	if event.is_action_pressed("Shoot"):
		shoot()
	
	if event.is_action_pressed("Reload"):
		reload() 

func Initialize(_start_weapons : Array) -> void:
	for weapon in _weapon_resources:
		weapon_list[weapon.weapon_name] = weapon
		
	for i in _start_weapons:
		weapon_stack.push_back(i)
	
	current_weapon = weapon_list[weapon_stack[0]]
	emit_signal("Update_Weapon_Stack", weapon_stack)
	enter()
	
func enter():
	animation_player.queue(current_weapon.pick_up_animation)
	emit_signal("Weapon_Changed", current_weapon.weapon_name)
	emit_signal("Update_Ammo", [current_weapon.current_ammo, current_weapon.reserve_ammo])

func exit(_next_weapon: String):
	if _next_weapon != current_weapon.weapon_name:
		if animation_player.get_current_animation() != current_weapon.drop_animation:
			animation_player.play(current_weapon.drop_animation)
			next_weapon = _next_weapon

func Change_Weapon(weapon_name : String):
	current_weapon = weapon_list[weapon_name]
	next_weapon = ""
	enter()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == current_weapon.drop_animation:
		Change_Weapon(next_weapon)
	
	elif anim_name == current_weapon.shoot_animation:
		if current_weapon.auto_fire and Input.is_action_pressed("Shoot"):
			shoot()

func shoot():
	if current_weapon.current_ammo != 0:
		if !animation_player.is_playing():
			animation_player.play(current_weapon.shoot_animation)
			current_weapon.current_ammo -= 1
			emit_signal("Update_Ammo", [current_weapon.current_ammo, current_weapon.reserve_ammo])
			var Camera_Collision = Get_Camera_Collision()
			match current_weapon.Type:
				NULL:
					print("Weapon Type not Chosen")
				HITSCAN:
					Hit_Scan_Collision(Camera_Collision	)
				PROJECTILE:
					pass
	else:
		reload()

func reload():
	if current_weapon.current_ammo == current_weapon.magazine:
		return
	elif !animation_player.is_playing():
		if current_weapon.reserve_ammo != 0:
			animation_player.play(current_weapon.reload_animation)
			
			var Reload_Amount = min(current_weapon.magazine-current_weapon.current_ammo, current_weapon.magazine, current_weapon.reserve_ammo)
			
			current_weapon.current_ammo = current_weapon.current_ammo + Reload_Amount
			current_weapon.reserve_ammo = current_weapon.reserve_ammo - Reload_Amount
			emit_signal("Update_Ammo", [current_weapon.current_ammo, current_weapon.reserve_ammo])
		
		else:
			animation_player.play(current_weapon.out_of_ammo_animation)

func Get_Camera_Collision() -> Vector3:
	var camera = get_viewport().get_camera_3d()
	var viewport = get_viewport().get_size()
	
	var Ray_Origin = camera.project_ray_origin(viewport/2)
	var Ray_End = Ray_Origin + camera.project_ray_normal(viewport/2) * current_weapon.weapon_range
	
	var New_Intersection = PhysicsRayQueryParameters3D.create(Ray_Origin, Ray_End)
	var Intersection = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if not Intersection.is_empty():
		var Col_Point = Intersection.position
		return Col_Point
	else:
		return Ray_End

func Hit_Scan_Collision(Collision_Point):
	var Bullet_Direction = (Collision_Point - bullet_point.get_global_transform().origin).normalized()
	var New_Intersection = PhysicsRayQueryParameters3D.create(bullet_point.get_global_transform().origin, Collision_Point+Bullet_Direction*2)
	
	var Bullet_Collsion = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if Bullet_Collsion:
		var Hit_Indicator = Debug_Bullet.instantiate()
		var world = get_tree().get_root()
		world.add_child(Hit_Indicator)
		Hit_Indicator.global_translate(Bullet_Collsion.position	)
		
		Hit_Scan_Damage(Bullet_Collsion.collider)
		

func Hit_Scan_Damage(Collider):
	if Collider.is_in_group("Target") and Collider.has_method("Hit_Successful"):
		Collider.Hit_Successful(current_weapon.damage)
	
	
