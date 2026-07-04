extends Node3D

## WWJMD Level Builder — Refined Convenience Store Floor Plan
## Stage 4 (Refinement): Lead Game Architect

@export var store_width: float = 20.0
@export var store_depth: float = 16.0
@export var wall_height: float = 3.5
@export var wall_thickness: float = 0.2

@export var aisle_count: int = 3
@export var shelf_per_aisle: int = 4

@export var player_spawn: Node3D = null
@export var enemy_template: PackedScene = null
@export var civilian_count: int = 3
@export var cop_count: int = 2

const DestructibleScript = preload("res://src/entities/destructible_item.gd")
const BrandDataScript = preload("res://src/resources/brand_data.gd")
const ShelfStockerScript = preload("res://src/tools/shelf_stocker.gd")

# Placeholder brands: [name, container_class, destruction_class, color]
const BRANDS = [
	["Chippy O's", "bag", "debris", Color(0.9, 0.75, 0.2)],
	["Fizz Cola", "can", "liquid", Color(0.85, 0.15, 0.15)],
	["ChocoBar", "box", "debris", Color(0.45, 0.28, 0.15)],
	["Aqua Pure", "bottle", "liquid", Color(0.3, 0.55, 0.9)],
]

# Gondola shelf layout: board surface heights, then per side a 3x3 snack
# grid — 3 columns along the board (x) by 3 rows deep (z, away from the spine)
const SHELF_LEVEL_YS = [0.4, 0.85, 1.3, 1.75]
const SHELF_SLOT_XS = [-0.6, 0.0, 0.6]
const SHELF_ROW_ZS = [0.14, 0.3, 0.46]

var _walls: Array[Node] = []
var _shelves: Array[Node] = []
var _brand_kits: Array = []
var _snacks_destroyed: int = 0
var _snacks_collected: int = 0
var _exit_fired: bool = false

signal level_exit_triggered()
signal snack_destroyed(total: int)
signal snack_collected(total: int)

func build_level() -> void:
	_build_floor()
	_build_walls()
	_build_coolers_and_freezers()
	_build_bathroom_doors()
	_build_manager_office()
	_build_checkout_counter()
	_build_aisles()
	_stock_shelves()
	_build_parking_lot()
	_build_getaway_van()
	_build_exit_trigger()
	_spawn_npcs()
	print("LevelBuilder: store built (walls=%d, shelves=%d)" % [_walls.size(), _shelves.size()])

func _build_floor() -> void:
	var floor = _make_box(store_width, 0.15, store_depth, Vector3(0, -0.075, 0), Color(0.45, 0.45, 0.5))
	floor.name = "Floor"
	add_child(floor)

func _build_walls() -> void:
	var hw = store_width * 0.5
	var hd = store_depth * 0.5
	var col = Color(0.8, 0.8, 0.85)
	var door_gap: float = 1.2  # entrance opening

	# Back wall (z = -hd) — solid
	var w = _make_box(store_width, wall_height, wall_thickness, Vector3(0, wall_height * 0.5, -hd), col)
	w.name = "Wall_Back"
	add_child(w)
	_walls.append(w)

	# Front wall (z = +hd) — two segments with door gap in center
	var seg_w = (store_width - door_gap) * 0.5
	var left_seg = _make_box(seg_w, wall_height, wall_thickness, Vector3(-(door_gap * 0.5 + seg_w * 0.5), wall_height * 0.5, hd), col)
	left_seg.name = "Wall_Front_Left"
	add_child(left_seg)
	_walls.append(left_seg)

	var right_seg = _make_box(seg_w, wall_height, wall_thickness, Vector3(door_gap * 0.5 + seg_w * 0.5, wall_height * 0.5, hd), col)
	right_seg.name = "Wall_Front_Right"
	add_child(right_seg)
	_walls.append(right_seg)

	# Left wall (x = -hw) — solid
	var left = _make_box(wall_thickness, wall_height, store_depth, Vector3(-hw, wall_height * 0.5, 0), col)
	left.name = "Wall_Left"
	add_child(left)
	_walls.append(left)

	# Right wall (x = +hw) — solid
	var right = _make_box(wall_thickness, wall_height, store_depth, Vector3(hw, wall_height * 0.5, 0), col)
	right.name = "Wall_Right"
	add_child(right)
	_walls.append(right)

func _build_coolers_and_freezers() -> void:
	var hd = store_depth * 0.5
	var hw = store_width * 0.5
	var z_start = -hd + 0.3
	var colors = [Color(0.6, 0.7, 0.8), Color(0.7, 0.6, 0.8)]  # cool blue, freezer purple

	for i in 5:
		var is_freezer = i >= 3
		var col = colors[1 if is_freezer else 0]
		var x = -hw + 1.0 + i * 2.0
		var w = _make_box(1.6, 2.2, 0.8, Vector3(x, 1.1, z_start), col)
		w.name = "Cooler_%d" % i
		add_child(w)

func _build_bathroom_doors() -> void:
	var hw = store_width * 0.5
	# On the left wall, near the back: two doors
	var door_y = wall_height * 0.5
	var z_positions = [-store_depth * 0.5 + 2.5, -store_depth * 0.5 + 4.5]
	var labels = ["MEN'S", "WOMEN'S"]
	var door_col = Color(0.5, 0.5, 0.4)

	for i in 2:
		var door = _make_box(0.9, 2.0, 0.1, Vector3(-hw + 0.1, door_y, z_positions[i]), door_col)
		door.name = "BathroomDoor_%s" % labels[i]
		add_child(door)

		# Label plaque above door
		var plaque = _make_box(0.6, 0.3, 0.05, Vector3(-hw + 0.1, door_y + 1.2, z_positions[i]), Color(0.9, 0.85, 0.85))
		plaque.name = "BathroomLabel_%s" % labels[i]
		add_child(plaque)

func _build_manager_office() -> void:
	var hw = store_width * 0.5
	var door_y = wall_height * 0.5
	var z_pos = -store_depth * 0.5 + 6.5  # further back than bathrooms

	# Manager door — distinct color
	var door = _make_box(0.9, 2.0, 0.1, Vector3(-hw + 0.1, door_y, z_pos), Color(0.3, 0.25, 0.2))
	door.name = "ManagerDoor"
	add_child(door)

	# Label
	var label = _make_box(0.7, 0.3, 0.05, Vector3(-hw + 0.1, door_y + 1.2, z_pos), Color(0.8, 0.7, 0.6))
	label.name = "ManagerLabel"
	add_child(label)

	# Code lock — small box next to door
	var lock = _make_box(0.15, 0.3, 0.08, Vector3(-hw + 0.3, door_y + 0.3, z_pos), Color(0.1, 0.1, 0.1))
	lock.name = "CodeLock"
	add_child(lock)

	# Keypad digits (4 small colored squares)
	for d in 4:
		var digit = _make_box(0.04, 0.04, 0.01, Vector3(-hw + 0.3 + (d - 1.5) * 0.06, door_y + 0.25, z_pos + 0.06),
			Color(0.8, 0.8, 0.2))
		digit.name = "CodeLockDigit_%d" % d
		add_child(digit)

func _build_checkout_counter() -> void:
	var hd = store_depth * 0.5
	var counter_z = hd - 3.0  # 3 units from front wall
	var counter = _make_box(3.0, 0.8, 0.6, Vector3(0, 0.4, counter_z), Color(0.55, 0.5, 0.45))
	counter.name = "CheckoutCounter"
	add_child(counter)

	# Register terminal on counter
	var reg = _make_box(0.3, 0.2, 0.2, Vector3(0.5, 0.8, counter_z - 0.1), Color(0.2, 0.2, 0.25))
	reg.name = "Register"
	add_child(reg)

func _build_aisles() -> void:
	# Rows of double-sided gondola shelf units with 4 stocked levels each
	var hd = store_depth * 0.5
	var aisle_z_start = -hd + 3.0
	var aisle_z_step = (hd * 2 - 6.0) / (aisle_count + 1)

	for row in aisle_count:
		var z = aisle_z_start + (row + 1) * aisle_z_step
		for col in shelf_per_aisle:
			var x = -6.0 + col * 2.5
			var unit = _build_shelf_unit(Vector3(x, 0, z))
			unit.name = "AisleShelf_%d_%d" % [row, col]
			_shelves.append(unit)

func _build_shelf_unit(pos: Vector3) -> Node3D:
	# Gondola: central spine panel with a board per level; snacks go on both sides
	var unit = Node3D.new()
	add_child(unit)
	unit.position = pos

	var spine = _make_box(2.0, 2.0, 0.1, Vector3(0, 1.0, 0), Color(0.6, 0.6, 0.7))
	spine.name = "Spine"
	unit.add_child(spine)

	for i in SHELF_LEVEL_YS.size():
		var board = _make_box(2.0, 0.05, 1.1, Vector3(0, SHELF_LEVEL_YS[i] - 0.025, 0), Color(0.5, 0.5, 0.6))
		board.name = "Board_%d" % i
		unit.add_child(board)

	return unit

func _stock_shelves() -> void:
	# Fill every level of every gondola on both sides with destructible snacks
	_build_brand_kits()
	for i in _shelves.size():
		var unit: Node3D = _shelves[i]
		for level in SHELF_LEVEL_YS.size():
			for side in 2:
				# Vary the brand per unit/level/side so aisles look mixed
				var kit = _brand_kits[(i + level * 2 + side) % _brand_kits.size()]
				var side_sign = 1.0 if side == 0 else -1.0
				var half_h = _mesh_half_height(kit["mesh_map"]["mesh"])
				for slot_x in SHELF_SLOT_XS:
					for row_z in SHELF_ROW_ZS:
						var snack = _make_snack(kit)
						unit.add_child(snack)
						snack.position = Vector3(
							slot_x, SHELF_LEVEL_YS[level] + half_h, side_sign * row_z)

func _build_brand_kits() -> void:
	# One shared BrandData/mesh/material set per brand — every snack instance
	# reuses these resources instead of allocating its own
	_brand_kits.clear()
	for row in BRANDS:
		var brand = BrandDataScript.new()
		brand.brand_name = row[0]
		brand.container_class = row[1]
		brand.destruction_class = row[2]
		var mat = StandardMaterial3D.new()
		mat.albedo_color = row[3]
		_brand_kits.append({
			"brand": brand,
			"mesh_map": ShelfStockerScript.build_mesh_map(row[1]),
			"material": mat,
		})

func _make_snack(kit: Dictionary) -> Node3D:
	# RigidBody3D root, frozen by the destructible script until a nearby
	# destruction blasts it loose
	var brand: BrandData = kit["brand"]
	var item = RigidBody3D.new()
	item.name = "Snack_%s" % brand.brand_name.replace(" ", "").replace("'", "")
	item.set_script(DestructibleScript)
	item.brand_data = brand
	item.max_health = 30.0
	item.dent_threshold = 20.0
	item.damaged_threshold = 10.0
	item.fragment_count = 4
	item.mass = 0.3

	var mi = MeshInstance3D.new()
	mi.name = "MeshInstance3D"
	mi.mesh = kit["mesh_map"]["mesh"]
	mi.material_override = kit["material"]
	item.add_child(mi)

	var col = CollisionShape3D.new()
	col.shape = kit["mesh_map"]["collider"]
	item.add_child(col)

	item.set_meta("mesh_instance", mi)
	item.destroyed.connect(_on_snack_destroyed)
	item.collected.connect(_on_snack_collected)
	return item

func _on_snack_destroyed() -> void:
	_snacks_destroyed += 1
	snack_destroyed.emit(_snacks_destroyed)

func _on_snack_collected() -> void:
	_snacks_collected += 1
	snack_collected.emit(_snacks_collected)

func _mesh_half_height(mesh: Mesh) -> float:
	if mesh is CylinderMesh:
		return mesh.height * 0.5
	if mesh is BoxMesh:
		return mesh.size.y * 0.5
	return 0.1

func _build_parking_lot() -> void:
	var hd = store_depth * 0.5
	var exterior_z = hd + 1.0  # just past the front wall

	# Asphalt
	var lot = _make_box(store_width * 1.5, 0.1, store_depth * 0.6, Vector3(0, -0.05, exterior_z + 3.0), Color(0.25, 0.25, 0.27))
	lot.name = "ParkingLot"
	add_child(lot)

	# Parking lines (thin boxes on ground)
	for i in 4:
		var line = _make_box(0.05, 0.02, 2.0, Vector3(-6.0 + i * 3.0, 0.0, exterior_z + 3.0), Color(0.9, 0.9, 0.85))
		line.name = "ParkingLine_%d" % i
		add_child(line)

func _build_getaway_van() -> void:
	var hd = store_depth * 0.5
	var van_pos = Vector3(0, 0.3, hd + 5.0)  # in parking lot

	# Van body (main cargo area)
	var body = _make_box(2.0, 1.4, 4.0, van_pos, Color(0.35, 0.35, 0.4))
	body.name = "VanBody"
	add_child(body)

	# Cab (front section)
	var cab = _make_box(2.0, 1.0, 1.2, van_pos + Vector3(0, 0.2, -2.4), Color(0.3, 0.3, 0.35))
	cab.name = "VanCab"
	add_child(cab)

	# Windshield (dark blue panel on cab front)
	var glass = _make_box(1.6, 0.5, 0.05, van_pos + Vector3(0, 0.4, -3.0), Color(0.15, 0.2, 0.3, 0.7))
	glass.name = "VanWindshield"
	add_child(glass)

	# Wheels (small dark cylinders at corners)
	for corner in [[-0.8, 0.1, -2.2], [0.8, 0.1, -2.2], [-0.8, 0.1, 2.0], [0.8, 0.1, 2.0]]:
		var wheel = _make_box(0.2, 0.2, 0.3, van_pos + Vector3(corner[0], corner[1], corner[2]), Color(0.1, 0.1, 0.1))
		wheel.name = "VanWheel"
		add_child(wheel)

	# Rear doors (open — showing dark interior)
	var rear = _make_box(1.6, 1.2, 0.05, van_pos + Vector3(0, 0.1, 2.0), Color(0.1, 0.1, 0.12))
	rear.name = "VanRearOpen"
	add_child(rear)

func _build_exit_trigger() -> void:
	var hd = store_depth * 0.5
	var van_pos = Vector3(0, 0.3, hd + 5.0)

	# Area3D that detects player near the van
	var area = Area3D.new()
	area.name = "ExitTrigger"
	var shape = BoxShape3D.new()
	shape.size = Vector3(3.0, 2.0, 5.0)
	var col_shape = CollisionShape3D.new()
	col_shape.shape = shape
	area.add_child(col_shape)
	area.transform.origin = van_pos + Vector3(0, 1.0, 0)
	add_child(area)

	# Connect to signal
	area.body_entered.connect(_on_exit_area_entered)

func _on_exit_area_entered(body: Node) -> void:
	if _exit_fired or not body.is_in_group("player"):
		return
	_exit_fired = true
	level_exit_triggered.emit()
	print("LevelBuilder: exit trigger activated by %s" % body.name)

func _spawn_npcs() -> void:
	if enemy_template == null:
		return

	var hd = store_depth * 0.5
	var spawn_points = [
		Vector3(-2, 0, hd - 2),
		Vector3(3, 0, hd - 3),
		Vector3(-4, 0, -hd + 3),
		Vector3(2, 0, -hd + 4),
		Vector3(0, 0, -hd + 2),
	]

	for i in civilian_count + cop_count:
		if i >= spawn_points.size():
			break
		var npc = enemy_template.instantiate() as Node3D
		npc.name = "NPC_%s_%d" % ["Cop" if i < cop_count else "Civilian", i]
		add_child(npc)
		npc.global_position = spawn_points[i]

func _make_box(w: float, h: float, d: float, pos: Vector3, color: Color) -> Node3D:
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
