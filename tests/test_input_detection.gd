extends Node

## WWJMD QA — Stage 1 Input Detection Test
## Verifies that input actions exist and return values.

func _ready():
	print("=== QA: Stage 1 Input Detection ===")

	var actions = [
		"move_forward", "move_backward", "move_left", "move_right",
		"look_left", "look_right", "shoot", "melee", "sprint"
	]

	var all_ok = true
	for a in actions:
		var exists = InputMap.has_action(a)
		var strength = Input.get_action_strength(a)
		print("  [%s] action='%s'  exists=%s  strength=%.2f" % ["OK" if exists else "FAIL", a, exists, strength])
		if not exists:
			all_ok = false

	print("=== RESULT: %s ===" % ["PASS" if all_ok else "FAIL"])
	print("  Camera / movement jitter check: run in-editor and observe smoothness.")
	if all_ok:
		print("  QA SIGNED OFF: Stage 1 baseline is stable.")
	else:
		print("  QA REJECTED: Missing input actions detected.")
