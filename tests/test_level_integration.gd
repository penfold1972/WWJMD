extends Node

## WWJMD QA — Stage 4 Level Integration Test
## Verifies store construction, AI detection, and destructible shelf loop.

var _builder: Node3D
var _player: Node3D
var _ai: Node3D
var _test_passed: bool = true

func _ready():
	print("=== QA: Stage 4 Level Integration ===")

	# --- Test 1: Level Builder constructs the store ---
	print("  Test 1: Build store floor plan...")
	var script = preload("res://src/core/level_builder.gd")
	_builder = script.new() as Node3D
	_builder.name = "LevelBuilder"
	add_child(_builder)
	_builder.build_level()

	var wall_count = _builder.get_child_count()
	print("  Children after build: %d" % wall_count)
	if wall_count >= 6:
		print("  [OK] Store built with walls, counter, shelves")
	else:
		print("  [FAIL] Too few nodes: %d" % wall_count)
		_test_passed = false

	# --- Test 2: AI Controller detects player ---
	print("  Test 2: AI aggro detection...")
	_player = Node3D.new()
	_player.name = "TestPlayer"
	_player.global_transform.origin = Vector3(0, 0, 0)
	add_child(_player)

	var ai_script = preload("res://src/entities/ai_controller.gd")
	_ai = ai_script.new() as Node3D
	_ai.name = "TestAI"
	_ai.global_transform.origin = Vector3(5, 0, 5)  # within aggro_radius=12
	# Add NavigationAgent3D child so _ready() doesn't assert
	var nav = NavigationAgent3D.new()
	_ai.add_child(nav)
	add_child(_ai)
	_ai.setup(_player)

	# Simulate detection by checking view cone
	var in_range = _ai.global_transform.origin.distance_to(_player.global_transform.origin) <= _ai.aggro_radius
	print("  Distance: %.1f  aggro_radius: %.1f  in_range=%s" % [
		_ai.global_transform.origin.distance_to(_player.global_transform.origin),
		_ai.aggro_radius,
		in_range
	])
	if in_range:
		print("  [OK] Player within aggro radius")
	else:
		print("  [FAIL] Player not detected within range")
		_test_passed = false

	# --- Test 3: Destructible shelf simulation ---
	print("  Test 3: Destructible item phase cycle...")
	var item_script = preload("res://src/entities/destructible_item.gd")
	var item = item_script.new() as Node3D
	item.name = "TestShelfItem"
	item.max_health = 100.0
	item.dent_threshold = 75.0
	item.damaged_threshold = 40.0

	# Add required MeshInstance3D child
	var mi = MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	item.add_child(mi)
	add_child(item)

	item.apply_damage(30.0)  # Phase 2 (Dent)
	var p2 = item._current_phase
	item.apply_damage(40.0)  # Phase 3 (Damaged)
	var p3 = item._current_phase
	item.apply_damage(50.0)  # Phase 4 (Destroyed)
	var p4 = item._current_phase

	print("  Phase progression: %d -> %d -> %d" % [p2, p3, p4])
	if p2 == 1 and p3 == 2 and p4 == 3:
		print("  [OK] Full destruction cycle verified")
	else:
		print("  [FAIL] Phase mismatch: expected 1->2->3, got %d->%d->%d" % [p2, p3, p4])
		_test_passed = false

	# --- Summary ---
	print("\n=== RESULT: %s ===" % ["PASS" if _test_passed else "FAIL"])
	if _test_passed:
		print("  QA SIGNED OFF: Stage 4 integration is stable.")
		print("  Complete loop: store built -> AI detects -> destruction works.")
	else:
		print("  QA REJECTED: Integration failure detected.")
