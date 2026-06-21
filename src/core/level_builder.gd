extends Node3D

## WWJMD Level Builder — Convenience Store Floor Plan
## Stage 4: Lead Game Architect

@export var store_width: float = 18.0
@export var store_depth: float = 14.0
@export var wall_height: float = 3.5
@export var wall_thickness: float = 0.2

@export var shelf_count: int = 3
@export var shelf_rows: int = 2

@export var player_spawn: Node3D = null
@export var enemy_template: PackedScene = null
@export var civilian_count: int = 2
@export var cop_count: int = 1

var _walls: Array[Node] = []
var _shelves: Array[Node] = []

func build_level() -> void:
	_build_walls()
	_build_checkout_counter()
	_build_shelf_rows()
	_spawn_npcs()
	print("LevelBuilder: store built (walls=%d, shelves=%d, npcs=%d)" % [
		_walls.size(), _shelves.size(), civilian_count + cop_count
	])

func _build_walls() -> void:
	# Floor
	var floor = _make_wall(store_width, 0.1, store_depth, Vector3(0, -0.05, 0), Color(0.5, 0.5, 0.5))
	add_child(floor)

	# Four walls
	var half_w = store_width * 0.5
	var half_d = store_depth * 0.5

	var data = [
		{ "pos": Vector3(0, wall_height * 0.5, -half_d),  "size": Vector3(store_width, wall_height, wall_thickness) },
		{ "pos": Vector3(0, wall_height * 0.5, half_d),   "size": Vector3(store_width, wall_height, wall_thickness) },
		{ "pos": Vector3(-half_w, wall_height * 0.5, 0),  "size": Vector3(wall_thickness, wall_height, store_depth) },
		{ "pos": Vector3(half_w, wall_height * 0.5, 0),   "size": Vector3(wall_thickness, wall_height, store_depth) },
	]
	for i in 4:
		var d = data[i]
		var w = _make_wall(d["size"].x, d["size"].y, d["size"].z, d["pos"], Color(0.8, 0.8, 0.85))
		w.name = "Wall_%d" % i
		add_child(w)
		_walls.append(w)

func _build_checkout_counter() -> void:
	var counter = _make_wall(2.0, 0.8, 0.4, Vector3(2.0, 0.4, 3.0), Color(0.6, 0.55, 0.5))
	counter.name = "CheckoutCounter"
	add_child(counter)

func _build_shelf_rows() -> void:
	for row in shelf_rows:
		for col in shelf_count:
			var shelf = _make_wall(0.8, 1.6, 0.3, Vector3(
				-5.0 + col * 2.0,
				0.8,
				-3.0 + row * 4.0
			), Color(0.6, 0.6, 0.7))
			shelf.name = "Shelf_%d_%d" % [row, col]
			add_child(shelf)
			_shelves.append(shelf)

func _spawn_npcs() -> void:
	if enemy_template == null:
		return

	var spawn_points = [
		Vector3(-2, 0, -4),
		Vector3(3, 0, -5),
		Vector3(0, 0, -6),
	]

	for i in civilian_count + cop_count:
		if i >= spawn_points.size():
			break
		var npc = enemy_template.instantiate() as Node3D
		npc.name = "NPC_%s_%d" % ["Cop" if i < cop_count else "Civilian", i]
		npc.global_transform.origin = spawn_points[i]
		add_child(npc)

func _make_wall(w: float, h: float, d: float, pos: Vector3, color: Color) -> Node3D:
	var node = Node3D.new()
	var mi = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(w, h, d)
	mi.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	node.add_child(mi)

	var body = StaticBody3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(w, h, d)
	var col = CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	node.add_child(body)

	node.transform.origin = pos
	node.set_meta("mesh_instance", mi)
	return node

func get_shelf_mesh(shelf_node: Node) -> MeshInstance3D:
	return shelf_node.get_meta("mesh_instance", null) as MeshInstance3D
