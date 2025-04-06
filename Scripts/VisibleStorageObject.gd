extends StorageComponent

@export var padding: float = 0
@export var max_items: int = 100
@export var default_item_size: Vector3 = Vector3(0.1, 0.1, 0.1)
@export var show_debug_slots: bool = true

var visual_slots: Array[Transform3D] = []
var storage_area: Area3D = null
var parent_obj: Node3D = null

func _ready() -> void:
	parent_obj = get_parent()
	storage_area = parent_obj.get_node_or_null("StorageArea")
	if not storage_area:
		print("[VSO] StorageArea not found on ", parent_obj.name)
	else:
		print("[VSO] Found StorageArea: ", storage_area.name)
	await get_tree().process_frame
	_init_storage()
	storage_area.body_entered.connect(_on_storage_area_body_entered)
	storage_area.body_exited.connect(_on_storage_area_body_exited)

func _init_storage() -> void:
	recalculate_storage_slots(default_item_size, show_debug_slots)

func _calculate_grid_dimensions(container_size: Vector3, item_size: Vector3) -> Vector3:
	var x_slots = floor((container_size.x - padding) / (item_size.x + padding))
	var y_slots = floor((container_size.y - padding) / (item_size.y + padding))
	var z_slots = floor((container_size.z - padding) / (item_size.z + padding))
	return Vector3(x_slots, y_slots, z_slots)

func recalculate_storage_slots(item_size: Vector3, draw_debug := true) -> void:
	visual_slots.clear()
	_clear_slot_debug_meshes()
	if not storage_area:
		push_error("[VSO] Cannot calculate slots: storage_area is null")
		return
	var shape = storage_area.get_node_or_null("CollisionShape3D")
	if not shape or not shape.shape is BoxShape3D:
		push_error("[VSO] StorageArea must have a CollisionShape3D with BoxShape3D")
		return
	var box_size = shape.shape.size
	_calculate_grid_layout(box_size, item_size, draw_debug)

func _calculate_grid_layout(box_size: Vector3, item_size: Vector3, draw_debug: bool) -> void:
	var grid = _calculate_grid_dimensions(box_size, item_size)
	var total_width = grid.x * (item_size.x + padding)
	var total_height = grid.y * (item_size.y + padding)
	var total_depth = grid.z * (item_size.z + padding)
	var center_offset = Vector3(
		(box_size.x - total_width) * 0.5,
		(box_size.y - total_height) * 0.5,
		(box_size.z - total_depth) * 0.5
	)
	var origin = Vector3(
	-box_size.x * 0.5 + center_offset.x,
	-box_size.y * 0.5 + center_offset.y,
	-box_size.z * 0.5 + center_offset.z
)

	var index = 0
	for y in int(grid.y):
		for z in int(grid.z):
			for x in int(grid.x):
				if index >= max_items:
					break
				var local_pos = origin + Vector3(
					x * (item_size.x + padding),
					y * (item_size.y + padding),
					z * (item_size.z + padding)
				)
				var transform = Transform3D(Basis(), local_pos)
				visual_slots.append(transform)
				if draw_debug:
					_spawn_slot_debug_mesh(transform.origin, item_size, index)
				index += 1

func _spawn_slot_debug_mesh(pos: Vector3, size: Vector3, index: int) -> void:
	var ghost = MeshInstance3D.new()
	ghost.name = "SlotDebugMesh_%d" % index
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	ghost.mesh = box_mesh
	ghost.position = pos
	var mat = StandardMaterial3D.new()
	var t = float(index) / max(1.0, float(visual_slots.size()))
	mat.albedo_color = Color(1.0 - t, t, 0, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost.set_surface_override_material(0, mat)
	get_parent().add_child(ghost)

func _clear_slot_debug_meshes() -> void:
	for child in get_parent().get_children():
		if child.name.begins_with("SlotDebugMesh_"):
			get_parent().remove_child(child)
			child.queue_free()

func get_storage_slots() -> Array[Transform3D]:
	return visual_slots

func _on_storage_area_body_entered(body: Node) -> void:
	if body is RigidBody3D:
		var interactable = _find_interactable_in(body)
		if interactable and interactable is PickableInteractable:
			print("[VSO] Valid pickable item detected: ", body.name)

func _on_storage_area_body_exited(body: Node) -> void:
	print("[VSO] Item left storage area: ", body.name)

func _find_interactable_in(node: Node) -> Node:
	for child in node.get_children():
		if child is PickableInteractable:
			return child
	var parent = node.get_parent()
	if parent and parent is PickableInteractable:
		return parent
	return null
