@tool
extends Node3D

## WWJMD Procedural Shelf Stocker — Editor @Tool
## Stage 3: Tools & Technical Artist

const GRID_MAX: int = 20

@export var brand_data: Resource = null:
	set(value):
		brand_data = value
		if Engine.is_editor_hint():
			_regenerate_on_brand_change()

@export var grid_width: int = 4:
	set(value):
		grid_width = clamp(value, 1, GRID_MAX)
		if Engine.is_editor_hint():
			_regenerate_on_brand_change()

@export var grid_height: int = 3:
	set(value):
		grid_height = clamp(value, 1, GRID_MAX)
		if Engine.is_editor_hint():
			_regenerate_on_brand_change()

@export var spacing: Vector3 = Vector3(0.6, 0.4, 0.6)

@export var generate: bool = false:
	set(value):
		generate = value
		if value and Engine.is_editor_hint():
			_generate_shelf()
		generate = false

var _generated_items: Array[Node] = []
var _is_generating: bool = false

func _generate_shelf() -> void:
	if _is_generating:
		return
	_is_generating = true

	_clear_shelf()
	if brand_data == null:
		push_warning("ShelfStocker: no BrandData assigned — skipping generation")
		_is_generating = false
		return

	var bd = brand_data as Resource
	var container = bd.get("container_class") if bd else "box"
	container = container if container is String else "box"

	var mesh_map := _build_mesh_map(container)
	var mat := _make_material(bd)

	for y in grid_height:
		for x in grid_width:
			var origin = Vector3(x * spacing.x, y * spacing.y, 0.0)
			var item = _spawn_item(origin, mesh_map, mat)
			if item:
				_generated_items.append(item)

	print("ShelfStocker: generated %d items (%dx%d grid)" % [_generated_items.size(), grid_width, grid_height])
	_is_generating = false

func _regenerate_on_brand_change() -> void:
	if _generated_items.size() > 0:
		_clear_shelf()
		_generate_shelf()

func _clear_shelf() -> void:
	for child in _generated_items:
		if is_instance_valid(child):
			child.free()
	_generated_items.clear()

func _build_mesh_map(container: String) -> Dictionary:
	# Returns { mesh: Mesh, collider: Shape3D } for the given container type
	var map = {}
	match container:
		"can":
			map["mesh"] = CylinderMesh.new()
			map["mesh"].height = 0.25
			map["mesh"].top_radius = 0.08
			map["mesh"].bottom_radius = 0.06
			map["collider"] = CylinderShape3D.new()
			map["collider"].height = 0.25
			map["collider"].radius = 0.07
		"bottle":
			map["mesh"] = CylinderMesh.new()
			map["mesh"].height = 0.3
			map["mesh"].top_radius = 0.04
			map["mesh"].bottom_radius = 0.06
			map["collider"] = CylinderShape3D.new()
			map["collider"].height = 0.3
			map["collider"].radius = 0.05
		"bag":
			map["mesh"] = BoxMesh.new()
			map["mesh"].size = Vector3(0.2, 0.3, 0.15)
			map["collider"] = BoxShape3D.new()
			map["collider"].size = Vector3(0.2, 0.3, 0.15)
		_:
			map["mesh"] = BoxMesh.new()
			map["mesh"].size = Vector3(0.2, 0.2, 0.15)
			map["collider"] = BoxShape3D.new()
			map["collider"].size = Vector3(0.2, 0.2, 0.15)
	return map

func _make_material(bd: Resource) -> Material:
	var mat = StandardMaterial3D.new()
	var tex = bd.get("product_texture") if bd else null
	if tex is Texture2D:
		mat.albedo_texture = tex
	else:
		# Fallback: random pastel color
		mat.albedo_color = Color(
			randf_range(0.4, 0.9),
			randf_range(0.4, 0.9),
			randf_range(0.4, 0.9)
		)
	return mat

func _spawn_item(origin: Vector3, mesh_map: Dictionary, mat: Material) -> Node3D:
	var item = Node3D.new()
	item.name = "ShelfItem_%d_%d" % [grid_width, grid_height]

	# Mesh
	var mi = MeshInstance3D.new()
	mi.mesh = mesh_map["mesh"]
	mi.material_override = mat
	item.add_child(mi)

	# Collision
	var col = StaticBody3D.new()
	var cs = CollisionShape3D.new()
	cs.shape = mesh_map["collider"]
	col.add_child(cs)
	item.add_child(col)

	# 50% mirror variant
	if randf() < 0.5:
		mi.mesh = mi.mesh.duplicate()
		# Flip on Z axis for visual mirror
		mi.transform = mi.transform.scaled(Vector3(1, 1, -1))

	# Position
	item.transform.origin = origin

	add_child(item)
	item.owner = self  # Make visible in editor tree
	return item
