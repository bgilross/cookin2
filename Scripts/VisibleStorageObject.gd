extends StorageComponent

class_name VisibleStorageObject

@export var item_size: Vector3 = Vector3(0.1, 0.1, 0.1)
@export var show_debug_slots: bool = true
@export var is_static_storage: bool = false

var visual_slots: Array[Transform3D] = []
var storage_area: Area3D = null
var stored_objects: Array[Node] = []


func _ready() -> void:
	# Ensure our parent is a RigidBody3D or similar
	var parent_obj = get_parent()
	if not parent_obj:
		push_error("VisibleStorageObject have Parent object")
		return
		
	# Get reference to storage area which defines the storage volume
	storage_area = parent_obj.get_node_or_null("StorageArea")
	if not storage_area:
		push_error("StorageArea not found on " + parent_obj.name)
		return
		
	# Connect signals for item detection
	storage_area.body_entered.connect(_on_storage_area_body_entered)
	storage_area.body_exited.connect(_on_storage_area_body_exited)
	
	# Wait one frame to ensure everything is initialized
	await get_tree().process_frame
	
	# Create the storage slots
	_create_storage_slots()	
	
func main_interaction(interactor) -> void:
	# Handle interaction with the storage
	print("[VSO] Storage interaction from: ", interactor.name)	
	#if this thing is currently being held:
		#main_interaction would maybe pick other things up into it?
	#if NOT static storage, F would have the player pick this thang up
	
	
	#if IS static storatge 
		#if player hands empty
			#if shelf empty, do nothing
			#if shelf full, player take item
		#if player hands full
			#if held item storable
				#if shelf empty, store it //// OR SHOULD G handle this kind of thing, G for DROP G for STORE, F for pickup F for STORE item in HELD TRAY... i dunno
				#if shelf occupied, 
					#if helf item compatible with currently stored items store it
					#else do nothing
				#if shelf full do nothing
				

func store_item(item: Node) -> bool:
	# Check if we have available slots
	if stored_objects.size() >= visual_slots.size():
		print("[VSO] Storage is full")
		return false
		
	# Add to our stored items array
	stored_objects.append(item)
	
	# Get the first available slot
	var slot_index = stored_objects.size() - 1
	var slot_transform = visual_slots[slot_index]
	
	# Position the item in the slot (assuming it's a Node3D)
	if item is Node3D:
		item.position = slot_transform.origin
		
	print("[VSO] Stored item in slot ", slot_index)
	return true

func retrieve_last_item(interactor) -> bool:
	if stored_objects.is_empty():
		print("[VSO] Storage is empty")
		return false
		
	# Get the last stored item
	var item = stored_objects.pop_back()
	
	# You'd need to implement the logic to give this item to the interactor
	# This depends on how your pickup system works
	
	print("[VSO] Retrieved item for ", interactor.name)
	return true

func _on_storage_area_body_entered(body: Node) -> void:
	if body is RigidBody3D:
		var interactable = find_interactable_in(body)
		if interactable and interactable is PickableInteractable:
			print("[VSO] Valid pickable item detected: ", body.name)

func _on_storage_area_body_exited(body: Node) -> void:
	print("[VSO] Item left storage area: ", body.name)

func find_interactable_in(node: Node) -> Node:
	# Look for PickableInteractable in children
	for child in node.get_children():
		if child is PickableInteractable:
			return child
			
	# Check parent
	var parent = node.get_parent()
	if parent and parent is PickableInteractable:
		return parent
		
	return null

func _create_storage_slots() -> void:
	# Clean up any existing debug meshes
	_clear_slot_debug_meshes()
	visual_slots.clear()
	
	# Get the storage area shape
	var shape_node = storage_area.get_node_or_null("CollisionShape3D")
	if not shape_node or not shape_node.shape is BoxShape3D:
		push_error("StorageArea must have a CollisionShape3D with BoxShape3D")
		return
		
	var box_shape = shape_node.shape as BoxShape3D
	var box_size = box_shape.size
	
	# Calculate how many items can fit in each dimension
	var slots_x = int(box_size.x / item_size.x)
	var slots_y = int(box_size.y / item_size.y)
	var slots_z = int(box_size.z / item_size.z)
	
	print("[VSO] Calculated grid: ", slots_x, "x", slots_y, "x", slots_z, 
		" (total slots: ", slots_x * slots_y * slots_z, ")")
	
	# Calculate the total size that our grid will occupy
	var grid_size = Vector3(
		slots_x * item_size.x,
		slots_y * item_size.y,
		slots_z * item_size.z
	)
	
	# Calculate the empty space we need to distribute
	var remaining_space = Vector3(
		box_size.x - grid_size.x,
		box_size.y - grid_size.y,
		box_size.z - grid_size.z
	)
	
	# Calculate the start position with even margins on all sides
	var shape_pos = shape_node.position
	var start_pos = Vector3(
		shape_pos.x - (box_size.x / 2) + (remaining_space.x / 2) + (item_size.x / 2),
		shape_pos.y - (box_size.y / 2) + (remaining_space.y / 2) + (item_size.y / 2),
		shape_pos.z - (box_size.z / 2) + (remaining_space.z / 2) + (item_size.z / 2)
	)
	
	# Create slots, iterating from bottom to top, back to front, left to right
	var slot_index = 0
	for y in range(slots_y):
		for z in range(slots_z):
			for x in range(slots_x):
				var slot_pos = start_pos + Vector3(
					x * item_size.x,
					y * item_size.y, 
					z * item_size.z
				)
				
				# Create the transform for this slot
				var transform = Transform3D(Basis(), slot_pos)
				visual_slots.append(transform)
				
				# Create a debug visualization if enabled
				if show_debug_slots:
					_create_debug_mesh(slot_pos, item_size, slot_index)
					
				slot_index += 1
	
	print("[VSO] Created ", visual_slots.size(), " storage slots")

func _create_debug_mesh(position: Vector3, size: Vector3, index: int) -> void:
	var ghost = MeshInstance3D.new()
	ghost.name = "SlotDebugMesh_" + str(index)
	
	# Create a box mesh for the slot
	var box_mesh = BoxMesh.new()
	box_mesh.size = size * 0.9  # Slightly smaller to see individual slots
	ghost.mesh = box_mesh
	
	# Position the ghost mesh
	ghost.position = position
	
	# Create a semi-transparent material with color based on index
	var material = StandardMaterial3D.new()
	var t = float(index) / max(1.0, float(visual_slots.size() - 1))
	material.albedo_color = Color(1.0 - t, t, 0.5, 0.3)  # RGBA
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	ghost.set_surface_override_material(0, material)
	get_parent().add_child(ghost)

func _clear_slot_debug_meshes() -> void:
	for child in get_parent().get_children():
		if child.name.begins_with("SlotDebugMesh_"):
			child.queue_free()
