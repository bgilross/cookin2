extends Node3D

var debug_draws: Array[Dictionary] = []

func _process(_delta: float) -> void:
	_clear_old_draws()
	for draw in debug_draws:
		_draw_debug_box(draw.node, draw.color)
	debug_draws.clear()

func draw_collision_debug(node: Node3D, color: Color) -> void:
	debug_draws.append({ "node": node, "color": color })

func _draw_debug_box(node: Node3D, color: Color) -> void:
	var shapes: Array[CollisionShape3D] = _find_all_collision_shapes(node)

	for shape in shapes:
		if shape.shape == null:
			continue

		var mesh: Mesh = shape.shape.get_debug_mesh()
		if mesh == null:
			continue

		var aabb: AABB = mesh.get_aabb()
		var box: BoxMesh = BoxMesh.new()
		box.size = aabb.size

		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		mesh_instance.mesh = box
		mesh_instance.global_transform = shape.global_transform
		mesh_instance.material_override = _get_debug_material(color)
		mesh_instance.set_meta("debug_draw", true)
		add_child(mesh_instance)

		var label: Label3D = Label3D.new()
		label.text = shape.get_path()
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = shape.global_transform.origin + Vector3.UP * 0.1
		label.set_meta("debug_draw", true)
		add_child(label)

		await get_tree().create_timer(0.25).timeout

		if is_instance_valid(mesh_instance):
			mesh_instance.queue_free()
		if is_instance_valid(label):
			label.queue_free()

func _find_all_collision_shapes(node: Node) -> Array[CollisionShape3D]:
	var result: Array[CollisionShape3D] = []
	if node is CollisionShape3D:
		result.append(node)
	for child in node.get_children():
		if child is Node:
			result += _find_all_collision_shapes(child)
	return result

func _get_debug_material(color: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.4
	return mat

func _clear_old_draws() -> void:
	for child in get_children():
		if child.has_meta("debug_draw"):
			child.queue_free()
