extends PickableInteractable

class_name PhysicsPickable


@export var use_continuous_cd: bool = true
@export var custom_mass: float = 1.0

@export var material_friction: float = 0.8
@export var material_bounce: float = 0.1
@export var material_absorbent: bool = false
@export var material_rough: bool = false

func _ready():
	print("ready from BALL")
	call_deferred("initialize_physics")

func initialize_physics():
	print("intializing Physics!")
	var rigidBody := get_parent() as RigidBody3D
	if not is_instance_valid(rigidBody):
		push_error("PhysicsPickable requires a RigidBody3D as it's parent...")
		return
	
	var mat := PhysicsMaterial.new()
	mat.friction = material_friction
	mat.bounce = material_bounce
	mat.absorbent = material_absorbent
	mat.rough = material_rough
	
	rigidBody.physics_material_override = mat
	
	rigidBody.continuous_cd = use_continuous_cd
	rigidBody.mass = custom_mass
	rigidBody.sleeping = false
	rigidBody.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	
		
