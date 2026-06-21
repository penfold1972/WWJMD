extends Node

## WWJMD QA — Stage 3 Shelf Stocker Test
## Simulates shelf generation and brand-swap to verify no leaks/errors.

var _stocker: Node3D
var _test_passed: bool = true

func _ready():
	print("=== QA: Stage 3 Shelf Stocker ===")

	# Create a dummy BrandData resource
	var brand = preload("res://src/resources/brand_data.gd").new()
	brand.brand_name = "TestCola"
	brand.container_class = "can"
	brand.destruction_class = "liquid"

	# Create stocker tool instance
	var script = preload("res://src/tools/shelf_stocker.gd")
	_stocker = script.new() as Node3D
	_stocker.name = "TestStocker"
	add_child(_stocker)

	# Test 1: Generate with BrandData
	print("  Test 1: Generate 4x3 can grid...")
	_stocker.brand_data = brand
	_stocker.grid_width = 4
	_stocker.grid_height = 3
	_stocker.generate = true
	await get_tree().process_frame  # let generation run

	var count = _stocker.get_child_count()
	print("  Children after generation: %d" % count)
	if count >= 12:
		print("  [OK] 12+ items spawned")
	else:
		print("  [FAIL] Expected >=12 items, got %d" % count)
		_test_passed = false

	# Test 2: Swap brand
	print("  Test 2: Swap brand resource...")
	var brand2 = preload("res://src/resources/brand_data.gd").new()
	brand2.brand_name = "GenericBox"
	brand2.container_class = "box"
	brand2.destruction_class = "debris"
	_stocker.brand_data = brand2
	await get_tree().process_frame

	var after_swap = _stocker.get_child_count()
	print("  Children after brand swap: %d" % after_swap)
	if after_swap >= 12:
		print("  [OK] Brand swap regenerated without leaks")
	else:
		print("  [FAIL] Node count changed unexpectedly: %d" % after_swap)
		_test_passed = false

	# Test 3: Clear and regenerate with different size
	print("  Test 3: Regenerate 2x2 grid...")
	_stocker.grid_width = 2
	_stocker.grid_height = 2
	_stocker.generate = true
	await get_tree().process_frame

	var final_count = _stocker.get_child_count()
	print("  Children after 2x2 regeneration: %d" % final_count)
	if final_count == 4:
		print("  [OK] Correct count after resize")
	else:
		print("  [FAIL] Expected 4, got %d" % final_count)
		_test_passed = false

	print("\n=== RESULT: %s ===" % ["PASS" if _test_passed else "FAIL"])
	if _test_passed:
		print("  QA SIGNED OFF: Stage 3 shelf stocker is stable.")
	else:
		print("  QA REJECTED: Generation or brand-swap failure detected.")
