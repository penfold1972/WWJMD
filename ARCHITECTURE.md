# WWJMD — Architecture Document
## "What Would John McClain Do?" — Godot 4.x 3D FPS

### Directory Tree
```
/wwjmd
├── ARCHITECTURE.md              # This file
├── project.godot                # Godot project configuration
                               # Input actions defined inline in project.godot
│
├── src/
│   ├── core/                    # Core systems & singletons
│   │   ├── globals.gd
│   │   ├── level_builder.gd          # Stage 4 store floor plan
│   │   └── game_manager.gd           # Refinement: game loop root
│   ├── entities/                # Player, AI, destructibles
│   │   ├── player.tscn               # Player scene: capsule collider + eye-height camera
│   │   ├── player_controller.gd      # Movement, gravity, jump, mouse-look, hitscan shooting
│   │   ├── destructible_item.gd      # Stage 2
│   │   └── ai_controller.gd          # Stage 4 navmesh AI
│   ├── objects/                 # Level props & containers
│   ├── tools/                   # Editor utilities
│   │   └── shelf_stocker.gd          # Stage 3 @tool (static mesh map reused at runtime)
│   ├── ui/                      # Menus & overlays
│   │   ├── hud.gd                    # Crosshair, snack counter, objective hint
│   │   └── end_screen.gd             # Refinement: Play Again / Quit overlay
│   └── resources/               # Custom resources
│       └── brand_data.gd             # Stage 2
│
├── assets/
│   ├── models/                  # .glb/.blend source files
│   ├── textures/                # .png/.exr source textures
│   └── audio/                   # .wav/.ogg source audio
│
├── tests/
│   ├── test_input_detection.gd  # Stage 1 QA script
│   ├── test_destruction.gd      # Stage 2 QA script
│   ├── test_shelf_stocker.gd    # Stage 3 QA script
│   └── test_level_integration.gd # Stage 4 QA script
│
└── levels/                      # Stage 4 tutorial level (builder creates at runtime)
```

### Tutorial Gameplay Loop
1. `main.tscn` root runs `game_manager.gd`: builds the store (level_builder), spawns
   the player from `player.tscn`, adds the HUD, and wires the exit trigger.
2. `level_builder._stock_shelves()` places destructible branded snacks (BrandData +
   `destructible_item.gd`) on every aisle shelf.
3. The player shoots (left mouse, hitscan raycast from the camera); damage routes to
   the nearest ancestor with `apply_damage()`. Destroyed snacks update the HUD counter
   via the `snack_destroyed` signal.
4. Walking to the getaway van in the parking lot fires `level_exit_triggered`
   (player-only, one-shot), pausing the tree and showing the end screen.
- Escape releases the mouse; clicking recaptures it (the recapture click never fires a shot).

### Data Flow & Conventions
- **Custom Resources** (`brand_data.gd`) live in `src/resources/` and are loaded via `ResourceLoader`.
- **@tool scripts** live in `src/tools/` and attach to Node3D in the editor.
- **Player Controller** uses `CharacterBody3D` with mouse-look via `_input(InputEventMouseMotion)`.
- **Destructible items** implement a 4-phase health state machine. Fragments auto-delete after 5 s.
- **QA scripts** are standalone `.gd` files that can be attached to a Node in a test scene or run via `--script`.

### PETRR Workflow
Every stage follows: **Plan → Execute → Test → Review → Refine**.
QA Lead signs off before moving to the next stage.
