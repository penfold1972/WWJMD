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

## Stage 3 — Procedural Shelf Stocker Tool

### Added
- `src/tools/shelf_stocker.gd` — Editor `@tool` script (Node3D) that procedurally spawns branded item grids.
- `tests/test_shelf_stocker.gd` — QA test that generates grids, swaps brands, and verifies node counts.

### Bugs Fixed During Review
1. **`this` → `self`** — GDScript has no `this` keyword; used `self` for `item.owner` assignment (line 144).
2. **Re-entrant generation** — Property setters for brand/grid could call `_generate_shelf` while `generate` toggle also calls it. Added `_is_generating` guard flag.
3. **`queue_free` in clear step** — Deferred deletion caused temporary duplicates during regeneration. Switched to immediate `free()` in the editor-only clear path.

### Design Details
- Exports: `brand_data`, `grid_width` (1–20), `grid_height` (1–20), `spacing` (Vector3), `generate` (bool toggle).
- Grid layout: nested loops, items placed at `(x*spacing.x, y*spacing.y, 0)`.
- Mirror variant: 50% chance per item; flips mesh transform on Z axis.
- Container types: `can` (cylinder), `bottle` (cylinder), `bag` (box), default (box).
- Material: pulls `product_texture` from BrandData; falls back to random pastel color.
- Protection: all generation gated by `Engine.is_editor_hint()` — never runs in-game.

## Stage 4 — Munchies Tutorial Level Integration

### Added
- `src/entities/ai_controller.gd` — Navmesh-driven AI with IDLE → ALERT → CHASE → ATTACK state machine.
- `src/core/level_builder.gd` — Procedural store floor plan builder (walls, checkout counter, shelf rows, NPC spawns).
- `tests/test_level_integration.gd` — End-to-end QA test: build store → AI aggro → destruction cycle.
- `levels/` directory — Ready for `.tscn` scenes.

### Bugs Fixed During Review
1. **`level_builder.gd` — `node.mesh_instance` was a class member, not a node property** — `_make_wall` tried to store `mesh_instance` on the returned Node3D, but the variable belonged to the LevelBuilder class. Replaced with `node.set_meta("mesh_instance", mi)` and a `get_shelf_mesh()` accessor.
2. **`level_builder.gd` — Shelf material assignment referenced invalid property** — `shelf.mesh_instance` was nil. Now uses `get_meta` to retrieve the MeshInstance3D.

### Design Details
- **Floor plan**: 18×14 m store with 4 perimeter walls, checkout counter at front, 2 rows × 3 shelves.
- **AI Controller**: 12 m aggro radius, 55° view cone. Chases at 4.0 m/s. Returns to origin if player leaves 24 m range.
- **NPC roles**: `civilian` (placeholder) and `cop` (placeholder). Spawned at predefined positions.
- **Integration**: Level builder, AI controller, destructible items all wired for the complete "enter → shoot → destroy" loop.

## Refinement Pass — Level Layout Overhaul

### Bugs Found & Fixed

1. **`ARCHITECTURE.md` — Still referenced deleted `default_input_map.tres`** (line 9). Replaced with inline comment.
2. **`destructible_item.gd` — Misleading `has_method("get_container_class")` check** — brand_data.gd doesn't define that method. Simplified to direct `get("container_class")`.
3. **`destructible_item.gd` — Wrong particle cleanup formula** — used `lifetime * duration * 1.5` instead of `duration + lifetime * 1.5`. Fixed.
4. **`ai_controller.gd` — Dead variable `_move_dir`** — declared but never assigned or read. Commented as reserved.
5. **`ai_controller.gd` — Incorrect `look_at` third parameter** — passed `true` for `use_modelview` instead of default `false`. Changed to omit third arg.
6. **`shelf_stocker.gd` — Duplicate item names** — all items got `ShelfItem_<grid_w>_<grid_h>` (same for every item). Changed to use `_generated_items.size()` for unique names.
7. **`test_destruction.gd` — Fragment cleanup checked wrong group** — used `get_nodes_in_group("fragments")` but fragments are never added to a group. Changed to count `RigidBody3D` children.

### Assets Added (needed to run in Godot)
- `assets/icon.svg` — Project icon with "WWJMD v0.1.0" branding.
- `assets/default_env.tres` — Default environment (ambient color, sky energy) so viewport isn't black.
- `project.godot` updated to reference both.

## Refinement Pass — Level Layout Overhaul

### Redesigned Store Floor Plan (`src/core/level_builder.gd`)
Complete rewrite of the convenience store layout per user specs:

| Feature | Implementation |
|---------|---------------|
| **Aisles in the middle** | 3 aisles × 4 shelves, evenly spaced across the store's depth |
| **Counter near the door** | Checkout counter + register terminal, 3 units from front wall |
| **Coolers & freezers (back wall)** | 5 units lining the back wall; last 2 are purple "freezer", first 3 are blue "cooler" |
| **Manager door + code lock** | Dark brown door on left wall; adjacent black lock box with 4 yellow digit indicators |
| **Bathrooms** | Two doors on left wall (Men's / Women's) with labeled plaques |
| **Parking lot** | Asphalt ground + white parking lines outside the front entrance |
| **Getaway van** | Box-modeled van (body, cab, windshield, wheels, open rear doors) in the lot |
| **Exit trigger** | Area3D near the van; emits `level_exit_triggered` when a CharacterBody3D enters |

### Other Changes
- `_make_wall()` renamed to `_make_box()` — now used for all structural geometry.
- Front wall split into two segments with a 1.2-unit door gap.
- NPC spawn points redistributed across the store interior.
- QA test updated to verify all 6 new features (cooler, manager door, bathroom, code lock, van, exit trigger).

### Game Loop Wiring
- `src/core/game_manager.gd` — New root game loop: builds level, spawns player, connects exit trigger → end screen.
- `src/ui/end_screen.gd` — CanvasLayer overlay with "MISSION COMPLETE" title, "Play Again" (reloads scene) and "Quit Game" (quits) buttons.
- Exit flow: Player reaches getaway van → Area3D detects CharacterBody3D → `level_exit_triggered` signal → `GameManager._on_level_exit()` → `EndScreen.show()` overlay.
- When no `player_scene` is assigned, GameManager spawns a default CharacterBody3D + Camera3D automatically.
