extends InteractableObject

class_name PickableInteractable

@export var can_pickup : bool = true
@export var can_hold : bool = true
@export var pickup_offset: Vector3 = Vector3.ZERO
@export var pickup_rotation: Vector3 = Vector3.ZERO

var is_held: bool = false
var holder: Node3D = null

@onready var body := get_parent() as RigidBody3D

func _ready():
	interaction_prompt = "Press [F] to Pickup!"

func main_interaction(interactor = null):
	if can_interact:
		attempt_pickup(interactor)
	else:
		print("Item: ", body.name,  " status not interactable")

func drop():
	if not is_held:
		print("how the heck,,, item can't be dropped")
		return

	# Cache tree root BEFORE removing anything
	var world_root = get_tree().root
	
	var hold_point = body.get_parent()
	hold_point.remove_child(body)

	# Re-add the body to the world
	world_root.add_child(body)

	var forward = holder.global_transform.basis.z.normalized()
	var start_pos = hold_point.global_transform.origin
	body.global_transform.origin = start_pos

	body.freeze = false
	body.collision_layer = 1
	body.collision_mask = 1
	
	body.linear_velocity = holder.get_real_velocity()
	
	holder.held_item = null
	is_held = false
	can_interact = true
	holder = null
	
	
func attempt_pickup(interactor: Node3D):
	if not can_pickup:
		print("Item status is not set to can_pickup")
		return
	
	var hold_point = interactor.get_node_or_null("MainCamera/HoldPoint")
	if not hold_point:
		print("No Hold point found on interactor: ", interactor.name)
		#could also build a temp hold point on whatever interactor, 
		return
		
	if not "held_item" in interactor:
		print("Interactor has NO var for storing obj as held_item")
		return
	
	if interactor.held_item:
		print("interactor: ", interactor.name, " is already holding item: ", interactor.held_item)
		return
	
	print(body.name, " is getting picked up by, ", interactor.name)
	
	var current_parent = body.get_parent()
	current_parent.remove_child(body)		
	hold_point.add_child(body)	
	
	is_held = true
	holder = interactor
	body.angular_velocity = Vector3.ZERO
	body.linear_velocity = Vector3.ZERO
	
	body.transform.origin = pickup_offset
	body.rotation = pickup_rotation
	
	# Store original collision mask/layer for restoring later
	var original_layer = body.collision_layer
	var original_mask = body.collision_mask

	# Disable collisions when held
	body.collision_layer = 0
	body.collision_mask = 0
	
	can_interact = false
	body.freeze = true
	interactor.held_item = body 
