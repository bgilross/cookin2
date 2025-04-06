extends RigidBody3D
class_name Pickable

#physics stuff
@export var has_physics: bool = true
@export var use_continuous_cd: bool = true
@export var custom_mass: float = 1.0
@export var material_friction: float = 0.8
@export var material_bounce: float = 0.8
@export var material_absorbent: bool = false
@export var material_rough: bool = false

#pickable stuff

@export var can_pickup : bool = true
@export var can_hold : bool = true
@export var can_store : bool = true
@export var pickup_offset: Vector3 = Vector3.ZERO
@export var pickup_rotation: Vector3 = Vector3.ZERO
@export var interaction_prompt: String = "Press [F] to Pickup!"
var is_held: bool = false
var holder: Node3D = null
var current_parent: Node3D = null
var current_layer: int = 1
var current_mask: int = 1

func _ready():
	if has_physics:
		var mat := PhysicsMaterial.new()
		mat.friction = material_friction
		mat.bounce = material_bounce
		mat.absorbent = material_absorbent
		mat.rough = material_rough
		
		self.physics_material_override = mat	
		self.continuous_cd = use_continuous_cd
		self.mass = custom_mass
		self.sleeping = false
		self.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC	

func attempt_pickup(interactor: Node3D):
	if not can_pickup:
		print("Item status is not set to can_pickup")
		return	
	var held_item = interactor.held_item
	if not held_item:
		print("Interactor hands empty, attempting pickup and hold first")
		if not can_hold:
			print("Can't hold this item attempting to store in inventory")
			pickup_inventory(interactor)
			return
		else:
			print("Can Hold this item, pickup to hands")
			var hold_point = interactor.get_node("MainCamera/HoldPoint")
			if hold_point:
				print("found hold point calling pickupfunction ")				
				pickup_hands(interactor, hold_point)
	if held_item:
		print("Interactor is holding an item, checking if item is VSO/Usable")
		for child in held_item:
			if child is VisibleStorage:
				print("Held Item is type VisibleStorage, attempting to store ", self, " in ", child )
				pickup_storage(interactor, held_item)

func pickup_inventory(interactor : Node3D):
	print("attempting to add item,  ", self , "  to inventory of " , interactor)		
	
func pickup_hands(interactor : Node3D, hold_point : Node3D):
	print("attempting to pickup ", self , " into ", interactor, " hands at holdpooint: ", hold_point)
	prepare_item_pickup(hold_point)
	interactor.held_item = self
	holder = interactor
	is_held = true
	
func pickup_storage(interactor : Node3D, storage : VisibleStorage):
	print("attempting to pickup ", self , " into ", interactor , "storage device: ", storage)

func prepare_item_pickup(new_parent : Node3D):
	get_parent().remove_child(self)
	new_parent.add_child(self)
	current_parent = new_parent
	angular_velocity = Vector3.ZERO
	linear_velocity = Vector3.ZERO
	transform.origin = pickup_offset
	rotation = pickup_rotation
	can_pickup = false
	freeze = true	
	

func drop():
	#called when dropping from hands or dropoing from VSO
	# Cache tree root BEFORE removing anything
	var world_root = get_tree().root	
	var parent = get_parent()
	parent.remove_child(self)

	# Re-add the body to the world
	world_root.add_child(self)

	var forward = holder.global_transform.basis.z.normalized()
	var start_pos = parent.global_transform.origin
	global_transform.origin = start_pos

	freeze = false	
	
	var player_velocity = holder.get_real_velocity()
	linear_velocity = Vector3(player_velocity.x, 0.0, player_velocity.z)
	#linear_velocity = Vector3(player_velocity.x, -1.0, player_velocity.z)
	
	holder.held_item = null
	is_held = false
	can_pickup = true
	holder = null
