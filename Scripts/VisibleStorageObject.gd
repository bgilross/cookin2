# === VisibleStorageObject.gd ===
extends StorageComponent

@export_group("Storage Settings")
@export var padding: float = 0.02
@export var max_items: int = 100
@export var default_item_size: Vector3 = Vector3(0.1, 0.1, 0.1)
@export var show_debug_slots: bool = true
@export var layout_algorithm: LayoutAlgorithm = LayoutAlgorithm.GRID

# Size class definitions for standard inventory items
enum SizeClass {
	TINY,   # 0.05×0.05×0.05
	SMALL,  # 0.1×0.1×0.1
	MEDIUM, # 0.2×0.2×0.2
	LARGE,  # 0.3×0.3×0.3
	CUSTOM  # Non-standard size
}

# Layout algorithm options
enum LayoutAlgorithm {
	GRID,           # Simple grid layout
	COMPACT,        # Space-efficient packing
	WEIGHTED_CENTER # Heavier items in center
}

# State
var is_configured: bool = false
var item_type_mesh: Mesh = null
var item_size_class: SizeClass = SizeClass.SMALL
var visual_slots: Array[Transform3D] = []
var optimal_tray_size: Vector3 = Vector3.ZERO

var storage_area: Area3D = null

func _ready() -> void:
	print("[VSO] READY from ", self.name, " parent: ", get_parent().name)
	
	# First, look for storage area at the expected path
	storage_area = get_parent().get_node_or_null("StorageArea")
	
	# If not found, search recursively through parent's children
	if not storage_area:
		print("[VSO] StorageArea not found at direct path, searching children...")
		storage_area = _find_node_by_class(get_parent(), "Area3D")
	
	if not storage_area:
		push_error("[VSO] ERROR: VisibleStorageObject requires a node named 'StorageArea' of type Area3D")
		print_debug("[VSO] CRITICAL ERROR: No StorageArea found")
		return
	else:
		print("[VSO] Found StorageArea: ", storage_area.name)
	
	await get_tree().process_frame
	_init_storage()
	storage_area.body_entered.connect(_on_storage_area_body_entered)
	storage_area.body_exited.connect(_on_storage_area_body_exited)

func _find_node_by_class(node: Node, class_name_to_find: String) -> Node:
	if node.get_class() == class_name_to_find:
		return node
		
	for child in node.get_children():
		var result = _find_node_by_class(child, class_name_to_find)
		if result:
			return result
	
	return null

func _init_storage() -> void:
	print("[VSO] Running storage init")
	recalculate_storage_slots(default_item_size, show_debug_slots)
	_calculate_optimal_tray_size()

func _calculate_optimal_tray_size() -> void:
	# Get CollisionShape3D from storage area
	var shape = storage_area.get_node_or_null("CollisionShape3D")
	if not shape or not shape.shape is BoxShape3D:
		push_error("[VSO] StorageArea must have a CollisionShape3D with BoxShape3D")
		return
	
	var box_shape = shape.shape as BoxShape3D
	var current_size = box_shape.size
	
	# Calculate grid dimensions for item size
	var grid = _calculate_grid_dimensions(current_size, default_item_size)
	
	# Calculate optimal size that exactly fits the grid
	optimal_tray_size = Vector3(
		grid.x * default_item_size.x + (grid.x + 1) * padding,
		grid.y * default_item_size.y + (grid.y + 1) * padding,
		grid.z * default_item_size.z + (grid.z + 1) * padding
	)
	
	print("[VSO] Optimal tray size for a ", grid, " grid: ", optimal_tray_size)
	
	# Optionally update the actual shape size
	# box_shape.size = optimal_tray_size

func _calculate_grid_dimensions(container_size: Vector3, item_size: Vector3) -> Vector3:
	var x_slots = floor((container_size.x - padding) / (item_size.x + padding))
	var y_slots = floor((container_size.y - padding) / (item_size.y + padding))
	var z_slots = floor((container_size.z - padding) / (item_size.z + padding))
	return Vector3(x_slots, y_slots, z_slots)

func store_item(item: Node3D) -> bool:
	# Configure storage based on first item if needed
	if stored_items.is_empty() and not is_configured:
		var dims = _get_item_dimensions(item)
		item_size_class = _classify_item_size(dims)
		var std_size = _get_standard_size(item_size_class)
		recalculate_storage_slots(std_size, show_debug_slots)
		
		var mesh_instance = _find_mesh_instance(item)
		if mesh_instance:
			item_type_mesh = mesh_instance.mesh
		is_configured = true
	elif not _is_compatible_item_type(item):
		return false
	
	if visual_slots.size() <= stored_items.size():
		return false
	
	var slot = visual_slots[stored_items.size()]
	var root = get_parent()
	var parent_transform: Transform3D = Transform3D.IDENTITY
	if root is Node3D:
		parent_transform = (root as Node3D).global_transform
	
	# Temporarily remove item from parent
	var original_parent = item.get_parent()
	if original_parent:
		original_parent.remove_child(item)
	
	# Add to storage and position
	add_child(item)
	
	# Apply position with offset based on item size class
	item.global_transform = parent_transform * slot
	stored_items.append(item)
	return true

func remove_item(item: Node3D) -> Node3D:
	if not stored_items.has(item):
		return null
	stored_items.erase(item)
	if stored_items.is_empty():
		item_type_mesh = null
		item_size_class = SizeClass.SMALL
		is_configured = false
		recalculate_storage_slots(default_item_size)
	return item

func recalculate_storage_slots(item_size: Vector3, draw_debug := true) -> void:
	print("[VSO] Recalculating storage slots...")
	print("[VSO] Item size: ", item_size)
	print("[VSO] Padding: ", padding)

	# Clear previous slots and debug meshes
	visual_slots.clear()
	_clear_slot_debug_meshes()
	
	if not storage_area:
		push_error("[VSO] Cannot calculate slots: storage_area is null")
		return

	var shape = storage_area.get_node_or_null("CollisionShape3D")
	if not shape or not shape.shape is BoxShape3D:
		push_error("[VSO] StorageArea must have a CollisionShape3D with BoxShape3D")
		return

	print("[VSO] Found valid CollisionShape3D")
	var box_size = shape.shape.size
	print("[VSO] Box size: ", box_size)

	# Calculate slots based on selected algorithm
	match layout_algorithm:
		LayoutAlgorithm.GRID:
			_calculate_grid_layout(shape, box_size, item_size, draw_debug)
		LayoutAlgorithm.COMPACT:
			_calculate_compact_layout(shape, box_size, item_size, draw_debug)
		LayoutAlgorithm.WEIGHTED_CENTER:
			_calculate_weighted_layout(shape, box_size, item_size, draw_debug)

	print("[VSO] Created ", visual_slots.size(), " storage slots")

func _calculate_grid_layout(shape: Node3D, box_size: Vector3, item_size: Vector3, draw_debug: bool) -> void:
	var grid = _calculate_grid_dimensions(box_size, item_size)
	print("[VSO] Grid size (slots in x/y/z): ", grid)

	# Calculate origin with offset for centering the grid in the box
	var total_width = grid.x * (item_size.x + padding) + padding
	var total_height = grid.y * (item_size.y + padding) + padding
	var total_depth = grid.z * (item_size.z + padding) + padding
	
	var center_offset = Vector3(
		(box_size.x - total_width) / 2 + padding,
		(box_size.y - total_height) / 2 + padding,
		(box_size.z - total_depth) / 2 + padding
	)
	
	var origin = shape.transform.origin - box_size / 2 + center_offset
	
	var index = 0
	for y in int(grid.y):
		for z in int(grid.z):
			for x in int(grid.x):
				if index >= max_items:
					break
					
				var pos = origin + Vector3(
					x * (item_size.x + padding),
					y * (item_size.y + padding),
					z * (item_size.z + padding)
				)
				
				var transform = Transform3D(Basis(), pos)
				visual_slots.append(transform)
				
				if draw_debug:
					_spawn_slot_debug_mesh(transform.origin, item_size, index)
					
				index += 1

func _calculate_compact_layout(shape: Node3D, box_size: Vector3, item_size: Vector3, draw_debug: bool) -> void:
	# Compact layout tries to minimize wasted space by using a bin-packing algorithm
	# For simplicity, we'll implement a basic version that staggers items a bit
	
	var grid = _calculate_grid_dimensions(box_size, item_size)
	print("[VSO] Compact grid size (slots in x/y/z): ", grid)
	
	var origin = shape.transform.origin - box_size / 2 + item_size / 2 + Vector3.ONE * padding
	var index = 0
	
	# First layer - regular grid
	for z in int(grid.z / 2):
		for x in int(grid.x):
			if index >= max_items:
				break
				
			var pos = origin + Vector3(
				x * (item_size.x + padding),
				0,
				z * (item_size.z + padding) * 2
			)
			
			var transform = Transform3D(Basis(), pos)
			visual_slots.append(transform)
			
			if draw_debug:
				_spawn_slot_debug_mesh(transform.origin, item_size, index)
				
			index += 1
	
	# Second layer - staggered grid for better packing
	for z in int(grid.z / 2):
		for x in int(grid.x - 1):
			if index >= max_items:
				break
				
			var pos = origin + Vector3(
				x * (item_size.x + padding) + (item_size.x + padding) / 2,
				item_size.y + padding,
				z * (item_size.z + padding) * 2 + (item_size.z + padding)
			)
			
			var transform = Transform3D(Basis(), pos)
			visual_slots.append(transform)
			
			if draw_debug:
				_spawn_slot_debug_mesh(transform.origin, item_size, index)
				
			index += 1

func _calculate_weighted_layout(shape: Node3D, box_size: Vector3, item_size: Vector3, draw_debug: bool) -> void:
	# Weighted layout places heavier/more important items toward the center for balance
	
	var grid = _calculate_grid_dimensions(box_size, item_size)
	print("[VSO] Weighted grid size (slots in x/y/z): ", grid)
	
	var origin = shape.transform.origin - box_size / 2 + item_size / 2 + Vector3.ONE * padding
	
	# Calculate center of the grid
	var center_x = int(grid.x / 2)
	var center_z = int(grid.z / 2)
	
	# Create a list of positions sorted by distance from center
	var positions = []
	for y in int(grid.y):
		for z in int(grid.z):
			for x in int(grid.x):
				var grid_pos = Vector3(x, y, z)
				var center_dist = Vector2(x - center_x, z - center_z).length()
				positions.append({
					"pos": grid_pos,
					"dist": center_dist
				})
	
	# Sort positions by distance from center
	positions.sort_custom(func(a, b): return a.dist < b.dist)
	
	# Create slots from sorted positions
	var index = 0
	for pos_data in positions:
		if index >= max_items:
			break
			
		var grid_pos = pos_data.pos
		var pos = origin + Vector3(
			grid_pos.x * (item_size.x + padding),
			grid_pos.y * (item_size.y + padding),
			grid_pos.z * (item_size.z + padding)
		)
		
		var transform = Transform3D(Basis(), pos)
		visual_slots.append(transform)
		
		if draw_debug:
			_spawn_slot_debug_mesh(transform.origin, item_size, index)
			
		index += 1

func _get_item_dimensions(item: Node3D) -> Vector3:
	var mesh_instance = _find_mesh_instance(item)
	if mesh_instance and mesh_instance.mesh:
		var aabb = mesh_instance.mesh.get_aabb()
		return aabb.size * mesh_instance.scale
	return Vector3.ZERO

func _classify_item_size(dimensions: Vector3) -> SizeClass:
	var volume = dimensions.x * dimensions.y * dimensions.z
	
	if volume <= 0.000125:  # 0.05³
		return SizeClass.TINY
	elif volume <= 0.001:   # 0.1³
		return SizeClass.SMALL
	elif volume <= 0.008:   # 0.2³
		return SizeClass.MEDIUM
	elif volume <= 0.027:   # 0.3³
		return SizeClass.LARGE
	else:
		return SizeClass.CUSTOM

func _get_standard_size(size_class: SizeClass) -> Vector3:
	match size_class:
		SizeClass.TINY:
			return Vector3(0.05, 0.05, 0.05)
		SizeClass.SMALL:
			return Vector3(0.1, 0.1, 0.1)
		SizeClass.MEDIUM:
			return Vector3(0.2, 0.2, 0.2)
		SizeClass.LARGE:
			return Vector3(0.3, 0.3, 0.3)
		_:
			return default_item_size

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var result = _find_mesh_instance(child)
		if result:
			return result
	return null

func _is_compatible_item_type(item: Node3D) -> bool:
	if not is_configured or not item_type_mesh:
		return true
	var mesh_instance = _find_mesh_instance(item)
	if not mesh_instance:
		return false
	return mesh_instance.mesh == item_type_mesh

func _on_storage_area_body_entered(body: Node) -> void:
	print("[VSO] Item entered storage area: ", body.name)
	if body is RigidBody3D:
		# Check if the object is a valid item
		var interactable = _find_interactable_in(body)
		if interactable and interactable is PickableInteractable:
			print("[VSO] Valid pickable item detected")
			# You could auto-store the item or show a prompt

func _on_storage_area_body_exited(body: Node) -> void:
	print("[VSO] Item left storage area: ", body.name)

func _find_interactable_in(node: Node) -> Node:
	# Check children first
	for child in node.get_children():
		if child is PickableInteractable:
			return child
	
	# Check parent
	var parent = node.get_parent()
	if parent and parent is PickableInteractable:
		return parent
	
	return null

func _spawn_slot_debug_mesh(pos: Vector3, size: Vector3, index: int) -> void:
	print("[VSO] Creating debug mesh for slot ", index, " at position ", pos)
	
	var ghost = MeshInstance3D.new()
	ghost.name = "SlotDebugMesh_%d" % index
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	ghost.mesh = box_mesh
	
	ghost.position = pos
	
	# Create material with a more visible color and opacity
	var mat = StandardMaterial3D.new()
	
	# Color slots based on their distance from center for weighted layout
	if layout_algorithm == LayoutAlgorithm.WEIGHTED_CENTER:
		var center = visual_slots.size() / 2.0
		var t = float(index) / max(1.0, float(visual_slots.size()))
		# Gradient from red (center) to green (edge)
		mat.albedo_color = Color(1.0 - t, t, 0, 0.7)
	else:
		mat.albedo_color = Color(1, 0, 0, 0.7)  # Bright red with high opacity
	
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost.set_surface_override_material(0, mat)
	
	get_parent().add_child(ghost)
	print("[VSO] Added debug mesh to ", get_parent().name)

func _clear_slot_debug_meshes() -> void:
	print("[VSO] Clearing previous debug meshes")
	for child in get_parent().get_children():
		if child.name.begins_with("SlotDebugMesh_"):
			get_parent().remove_child(child)
			child.queue_free()
			print("[VSO] Removed debug mesh: ", child.name)

func get_storage_slots() -> Array[Transform3D]:
	return visual_slots
