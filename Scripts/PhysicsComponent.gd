extends Node
class_name PhysicsComponent



@export var use_continuous_cd: bool = true
@export var custom_mass: float = 1.0

@export var material_friction: float = 0.8
@export var material_bounce: float = 0.1
@export var material_absorbent: bool = false
@export var material_rough: bool = false

@onready var body := get_parent() as RigidBody3D

func _ready():
	print("ready from PhysicsComponent")
	call_deferred("initialize_physics")

func initialize_physics():
	if body:
		print("initilizing physics from physics component in :", body.name)
	else:
		print("no body?")
	
	var mat := PhysicsMaterial.new()
	mat.friction = material_friction
	mat.bounce = material_bounce
	mat.absorbent = material_absorbent
	mat.rough = material_rough
	
	body.physics_material_override = mat	
	body.continuous_cd = use_continuous_cd
	body.mass = custom_mass
	body.sleeping = false
	body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	
		
