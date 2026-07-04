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

### Godot 4 Compatibility Fixes
- **`default_env.tres`** — Invalid format; removed. Environment reference removed from `project.godot`.
- **`end_screen.gd`** — Renamed `show()` → `build_ui()`. `CanvasLayer` has a built-in `show()` method inherited from `Node`, causing a static-function conflict. Also removed static qualifier — `get_tree()` can't be called from a static context.
- **`game_manager.gd`** — Changed `end.show()` to `end_script.new()` + `end_screen.build_ui()`.

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
- Exit flow: Player reaches getaway van → Area3D detects CharacterBody3D → `level_exit_triggered` signal → `GameManager._on_level_exit()` → `EndScreen.build_ui()` overlay.
- When no `player_scene` is assigned, GameManager spawns a default CharacterBody3D + Camera3D automatically.

## Playable Tutorial Pass — end-to-end gameplay loop

### Fixed (blocking — project could not run)
1. **`main.tscn` invalid scene syntax** — `script` was assigned a string path instead of
   `ExtResource("1")`, and `transform.rotation`/`transform.origin` are not valid `.tscn`
   keys. Rewrote the scene with proper `Transform3D(...)` values, added a
   `WorldEnvironment` with ambient light and shadow-casting sun.
2. **Input map was Godot 3 format** — `{"device": 1, "key": ..., "type": 2}` dictionaries
   don't deserialize into Godot 4 `InputEvent`s, so every action was empty. Rewrote all
   actions as `Object(InputEventKey/InputEventMouseButton, ...)`. New bindings:
   WASD move, Space jump, Shift sprint, Left Mouse shoot, E melee (reserved), Esc releases mouse.
3. **`global_transform` set before `add_child()`** in `game_manager` (player) and
   `level_builder` (NPCs) — errors in Godot 4 and loses the position. Reordered.
4. **Player had no collision shape, no gravity, camera at floor level** — added
   `src/entities/player.tscn` (capsule collider, camera at 1.6 m) and gravity + jump
   in `player_controller.gd`.
5. **`[physics] 3d/gravity` / `[rendering] renderer`** were Godot 3 setting names —
   now `3d/default_gravity` and `renderer/rendering_method`.
6. **`globals.gd` registered as autoload** (was written as one but never registered).

### Added (gameplay loop)
- **Hitscan shooting**: camera raycast on `shoot`, damage routed to the nearest ancestor
  with `apply_damage()` — lives in `_unhandled_input` so UI/recapture clicks never fire.
- **Stocked shelves**: `level_builder._stock_shelves()` places 3 destructible snacks per
  aisle shelf using 4 placeholder brands (bag/can/box/bottle) via BrandData; mesh shapes
  reuse `ShelfStocker.build_mesh_map()` (now static).
- **HUD** (`src/ui/hud.gd`): crosshair, "Snacks destroyed" counter (wired to the new
  `snack_destroyed` signal), objective hint.
- **Fall respawn**: game manager resets the player if they fall off the world.

### Fixed (gameplay)
- End screen was built twice (once in `_ready`, once by the game manager) and appeared
  with the mouse still captured — now built once, shows the cursor, pauses the tree,
  and uses a properly centered container layout.
- Exit trigger fired for any `CharacterBody3D` and could fire repeatedly — now
  player-group-only and one-shot.
- `shelf_stocker.gd` set `item.owner = self`, which only persists when the stocker is
  the scene root — now uses `edited_scene_root`.
- `brand_data.gd` gained `class_name BrandData`.

## Gondola Shelves & Collect-vs-Destroy Scoring

### Changed
- **Aisle shelves rebuilt as double-sided gondolas**: central spine panel with 4 shelf
  boards per unit; snacks stocked on every level on both sides (4 slots x 4 levels x
  2 sides = 32 snacks per unit, 384 in the store). Brands vary per unit/level/side.
  Snack meshes/materials/collision shapes are shared per brand instead of allocated
  per item.
- HUD hint and scoring flipped to match the new design: collecting is the goal,
  destruction is penalized.

### Added
- **Collect interaction**: aiming at a snack within 2.5 m shows an "[E] Collect"
  prompt; pressing E collects it (new `collect()` + `collected` signal on
  `destructible_item.gd`, `interact` action bound to E — melee moved to F).
- **Scoring**: +10 per collected snack, -5 per destroyed snack. Live
  Collected/Destroyed/Score readout on the HUD; final tally on the end screen.
- `.gitignore`: ignore Godot 4.4+ `*.uid` companion files.

## 3x3 Shelf Groups & Explosion Physics

### Changed
- **Snacks now sit in 3x3 groups** per shelf side per level (3 columns x 3 rows deep)
  instead of a single row — 72 snacks per gondola, 864 in the store. Shelf boards
  widened to 1.1 m deep to hold the grid.
- **Snacks are now frozen RigidBody3D items** (destructible_item.gd extends
  RigidBody3D). Frozen bodies behave as static scenery, so hundreds cost nothing.

### Added
- **Explosion knock-back**: destroying a snack blasts every snack within 0.7 m —
  they unfreeze, take a distance-scaled impulse (slightly upward-biased), and become
  live physics objects that slide along the shelf or tumble off it. Cans and bottles
  roll. Destroyed items drop out of collision immediately so neighbors fly through
  the space they occupied. Knocked-down snacks remain shootable and collectible.

## Floor Plan Fill — right side of the store

### Changed
- Aisles extended from 4 to 5 gondola units per row and re-centered
  (columns now computed from `shelf_per_aisle` instead of a hardcoded start),
  filling the dead space right of center. 15 gondolas / 1080 snacks total.
- Coolers extended from 5 to 7 units along the back wall (last 3 are freezers).
- The ~4 m strip along the right wall is left open on purpose — reserved as an
  open engagement area for the upcoming navmesh AI encounter.
