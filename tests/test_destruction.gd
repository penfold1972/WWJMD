extends Node

## WWJMD QA — Stage 2 Destruction Phase Test
## Verifies all 4 phases trigger correctly and fragments clean up.

const TEST_DAMAGE: float = 10.0

var _items: Array[Node] = []
var _test_passed: bool = true

func _ready():
	print("=== QA: Stage 2 Destruction Phases ===")

	# Simulate items by creating in-memory instances
	for i in 4:
		var item = preload("res://src/entities/destructible_item.gd").new()
		item.name = "TestItem_%d" % i
		item.max_health = 100.0
		item.dent_threshold = 75.0
		item.damaged_threshold = 40.0

		# Create a dummy mesh child so _ready() doesn't assert
		var mesh = MeshInstance3D.new()
		mesh.mesh = BoxMesh.new()
		item.add_child(mesh)
		mesh.owner = item

		add_child(item)
		_items.append(item)

	# Test each item through all phases
	for idx in range(_items.size()):
		var item = _items[idx]
		print("\n  --- Item %d ---" % idx)

		# Phase 1: Indestructible (full health)
		_test_phase(item, 0, "Indestructible", item.max_health)

		# Phase 2: Dent (apply damage to push below dent_threshold)
		var dent_damage = item.max_health - item.dent_threshold + 5.0
		item.apply_damage(dent_damage)
		_test_phase(item, 1, "Dent", item._health)

		# Phase 3: Damaged (apply damage to push below damaged_threshold)
		var dmg_damage = item._health - item.damaged_threshold + 5.0
		item.apply_damage(dmg_damage)
		_test_phase(item, 2, "Damaged", item._health)

		# Phase 4: Destroyed (apply lethal damage)
		item.apply_damage(item._health + 1.0)
		_test_phase(item, 3, "Destroyed", item._health)

	print("\n=== RESULT: %s ===" % ["PASS" if _test_passed else "FAIL"])
	if _test_passed:
		print("  All phase transitions verified.")
		print("  Fragment cleanup: wait 6s then check node count.")
	else:
		print("  QA REJECTED: Phase transition failure detected.")

	# Schedule fragment cleanup check
	var check = get_tree().create_timer(6.0)
	check.timeout.connect(_check_cleanup)

func _test_phase(item: Node, expected_phase: int, label: String, health: float) -> void:
	var actual = item._current_phase
	var ok = actual == expected_phase
	print("  [%s] %s phase: health=%.1f  expected=%d  actual=%d" % [
		"OK" if ok else "FAIL", label, health, expected_phase, actual
	])
	if not ok:
		_test_passed = false

func _check_cleanup() -> void:
	var children = get_children()
	var alive = 0
	for c in children:
		if c is RigidBody3D:
			alive += 1
	print("\n  Fragment cleanup check: %d RigidBody3D nodes remaining after 6s" % alive)
	if alive == 0:
		print("  QA SIGNED OFF: Stage 2 destruction framework is stable.")
	else:
		print("  QA WARNING: %d fragments still alive (may be expected if not in group)." % alive)
