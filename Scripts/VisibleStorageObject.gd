# === VisibleStorageObject.gd ===
extends StorageComponent

@export_group("Storage Settings")
@export var padding: float = 0.02
@export var max_items: int = 100
@export var default_item_size: Vector3 = Vector3(0.1, 0.1, 0.1)
@export var show_debug_slots: bool = true

# State
var is_configured: bool = false
var item_type_mesh: Mesh = null
var visual_slots: Array[Transform3D] = []

@onready var storage_area: Area3D = get_parent().get_node("StorageArea")

func _ready() -> void:
	print("[VSO] READY")
	if not storage_area:
		push_error("VisibleStorageObject requires a child node named 'StorageArea' with a CollisionShape3D")
		return

	print("[VSO] Has StorageArea")
	await get_tree().process_frame
	_init_storage()
	storage_area.body_entered.connect(_on_storage_area_body_entered)
	storage_area.body_exited.connect(_on_storage_area_body_exited)

func _init_storage() -> void:
	print("[VSO] Running deferred storage init")
	recalculate_storage_slots(default_item_size, show_debug_slots)

func store_item(item: Node3D) -> bool:
	if stored_items.is_empty() and not is_configured:
		var dims = _get_item_dimensions(item)
		recalculate_storage_slots(dims)
		var mesh_instance = _find_mesh_instance(item)
		if mesh_instance:
			item_type_mesh = mesh_instance.mesh
		is_configured = true
	elif not _is_compatible_item_type(item):
		return false
	
	if visual_slots.size() <= stored_items.size():
		return false
	
	var slot = visual_slots[stored_items.size()]
	var root = get_root_body()
	var parent_transform: Transform3D = Transform3D.IDENTITY
	if root is Node3D:
		parent_transform = (root as Node3D).global_transform
	item.global_transform = parent_transform * slot
	add_child(item)
	stored_items.append(item)
	return true

func remove_item(item: Node3D) -> Node3D:
	if not stored_items.has(item):
		return null
	stored_items.erase(item)
	if stored_items.is_empty():
		item_type_mesh = null
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

	var shape = storage_area.get_node("CollisionShape3D")
	if not shape or not shape.shape is BoxShape3D:
		push_error("StorageArea must use BoxShape3D")
		return

	print("[VSO] Found valid CollisionShape3D")
	var box_size = shape.shape.size
	print("[VSO] Box size: ", box_size)

	var grid = Vector3(
		floor(box_size.x / (item_size.x + padding)),
		floor(box_size.y / (item_size.y + padding)),
		floor(box_size.z / (item_size.z + padding))
	)
	print("[VSO] Grid size (slots in x/y/z): ", grid)

	var origin = -box_size / 2 + item_size / 2
	var index = 0

	for y in int(grid.y):
		for z in int(grid.z):
			for x in int(grid.x):
				if index >= max_items:
					break
				var pos = origin + Vector3(x, y, z) * (item_size + Vector3.ONE * padding)
				var transform = Transform3D(Basis(), pos)
				visual_slots.append(transform)
				if draw_debug:
					print("[VSO] Spawning debug slot mesh at index %d: %s" % [index, pos])
					_spawn_slot_debug_mesh(transform.origin, item_size, index)
				index += 1

func _get_item_dimensions(item: Node3D) -> Vector3:
	var mesh_instance = _find_mesh_instance(item)
	if mesh_instance and mesh_instance.mesh:
		var aabb = mesh_instance.mesh.get_aabb()
		return aabb.size * mesh_instance.scale
	return Vector3.ZERO

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
	if body.has_method("pickup"):
		print("Item entered storage area: ", body.name)

func _on_storage_area_body_exited(body: Node) -> void:
	if body.has_method("pickup"):
		print("Item left storage area: ", body.name)

func get_root_body() -> Node:
	var current = self
	while current.get_parent():
		current = current.get_parent()
	return current

func _spawn_slot_debug_mesh(pos: Vector3, size: Vector3, index: int) -> void:
	print("[VSO] Creating SlotDebugMesh_%d at %s with size %s" % [index, pos, size])
	var ghost = MeshInstance3D.new()
	ghost.name = "SlotDebugMesh_%d" % index
	ghost.mesh = BoxMesh.new()
	ghost.mesh.size = size
	var root = get_root_body()
	if root is Node3D:
		ghost.global_transform = (root as Node3D).global_transform * Transform3D(Basis(), pos)
	else:
		ghost.global_transform = Transform3D(Basis(), pos)
	ghost.visible = true
	ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0, 1, 0, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost.set_surface_override_material(0, mat)
	add_child(ghost)

func _clear_slot_debug_meshes() -> void:
	for child in get_children():
		if child.name.begins_with("SlotDebugMesh_"):
			remove_child(child)
			child.queue_free()

func get_storage_slots() -> Array[Transform3D]:
	return visual_slots
