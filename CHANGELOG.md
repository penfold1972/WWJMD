# CHANGELOG — WWJMD

## Stage 1 — Baseline Fixes (pre-commit)

### Bugs Fixed

1. **`default_input_map.tres` — Invalid Godot 4 format**
   - The `.tres` file used `[input_event]` section headers with numeric keys, which is not valid Godot 4 resource syntax.
   - **Fix:** Removed the file entirely. Input actions are now defined directly in `project.godot` under the `[input]` section, which is the standard Godot 4 approach.
   - Path: `project.godot` lines 9–44.

2. **`player_controller.gd` — Movement direction inverted**
   - Forward key caused backward movement. The `_input_dir.y` term was `move_backward - move_forward` instead of `move_forward - move_backward`.
   - **Fix:** Swapped the subtraction order so pressing W (forward) yields +1 on the Y axis, which correctly maps to `-global_transform.basis.z` (forward).
   - Path: `src/entities/player_controller.gd:34-36`.

3. **`player_controller.gd` — Lerp weight can exceed 1.0**
   - `delta * acceleration` (e.g., 0.016 * 12 = 0.19) is usually safe, but large delta spikes could push weight past 1.0, causing instant velocity snapping.
   - **Fix:** Wrapped the weight with `clamp(delta * acceleration, 0.0, 1.0)`.
   - Path: `src/entities/player_controller.gd:50-51`.

4. **`player_controller.gd` — Mouse capture tied to "shoot" action**
   - Using `Input.is_action_just_pressed("shoot")` to capture mouse would also fire a shot on capture. Changed to use `MOUSE_BUTTON_LEFT` directly.
   - **Fix:** Replaced action check with `Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)`.
   - Path: `src/entities/player_controller.gd:30-31`.

5. **`ARCHITECTURE.md` — References non-existent API**
   - Document mentioned `Input.get_look_...` which does not exist in Godot 4.
   - **Fix:** Updated to correctly reference `_input(InputEventMouseMotion)`.
   - Path: `ARCHITECTURE.md:41`.

### Design Observations
- `friction` export variable in `player_controller.gd` is declared but unused. Kept as a tuning placeholder for future refinement.
- `globals.gd` and `test_input_detection.gd` were clean with no issues.

## Stage 2 — Brand Data & Destructible Framework

### Added
- `src/resources/brand_data.gd` — Custom Resource with brand_name, product_texture, container_class, destruction_class.
- `src/entities/destructible_item.gd` — 4-phase health state machine (INDESTRUCTIBLE → DENT → DAMAGED → DESTROYED).
- `tests/test_destruction.gd` — QA test that cycles each phase and verifies fragment cleanup.

### Bugs Fixed During Review
1. **Dead code (`_original_mesh_data`)** — Stored vertex buffer data never used by the dent system (which uses scale deformation instead). Removed.
2. **Fragile resource casting** — `brand_data as Resource` then `.container_class` relied on duck-typing without a fallback. Replaced with safe `get("container_class")` access.
3. **Particles deleted with parent** — Phase 3 particles were `add_child` to the item, then deleted when Phase 4 calls `queue_free`. Reparented to `get_tree().root` so they survive and self-clean via timer.

### Design Details
- Phase 1 (Indestructible): absorbs hits, no visual change.
- Phase 2 (Dent): non-uniform scale distortion (0.92–0.98x on random axes).
- Phase 3 (Damaged): resets scale, spawns GPUParticles3D (debris for boxes/bags, liquid for cans/bottles).
- Phase 4 (Destroyed): hides mesh, spawns `fragment_count` RigidBody3D cubes with random velocity (3–8 m/s), auto-deletes after 5 s (with ±20% jitter).
- `is_mirror_variant` export ready for Stage 3 shelf stocker to set 50% chance.
