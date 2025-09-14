extends Resource

class_name WeaponResource

@export_group("Weapon Animations")
@export var weapon_name: String
@export var pick_up_animation: String
@export var idle_animation: String
@export var shoot_animation: String
@export var reload_animation: String
@export var change_animation: String
@export var drop_animation: String
@export var out_of_ammo_animation: String
@export var melee_animation: String

@export_group("Weapon Stats")
@export var has_ammo: bool = true
@export var current_ammo: int
@export var reserve_ammo: int
@export var magazine: int
@export var max_ammo: int
@export var damage: int
@export var melee_damage: float
@export var auto_fire: bool
@export var weapon_range: int
@export_flags("HitScan", "Projectile") var Type

@export_group("Weapon Behaviour")
@export var can_be_dropped: bool
@export var weapon_drop: PackedScene
@export var weapon_spray: PackedScene
@export var projectile_to_load: PackedScene
@export var incremental_reload: bool = false
