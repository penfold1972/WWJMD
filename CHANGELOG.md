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
