# WWJMD — Architecture Document
## "What Would John McClain Do?" — Godot 4.x 3D FPS

### Directory Tree
```
/wwjmd
├── ARCHITECTURE.md              # This file
├── project.godot                # Godot project configuration
├── default_input_map.tres       # 3D FPS input bindings
│
├── src/
│   ├── core/                    # Core systems & singletons
│   │   ├── globals.gd
│   │   └── level_builder.gd          # Stage 4 store floor plan
│   ├── entities/                # Player, AI, destructibles
│   │   ├── player_controller.gd
│   │   ├── destructible_item.gd      # Stage 2
│   │   └── ai_controller.gd          # Stage 4 navmesh AI
│   ├── objects/                 # Level props & containers
│   ├── tools/                   # Editor utilities
│   │   └── shelf_stocker.gd          # Stage 3 @tool
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

### Data Flow & Conventions
- **Custom Resources** (`brand_data.gd`) live in `src/resources/` and are loaded via `ResourceLoader`.
- **@tool scripts** live in `src/tools/` and attach to Node3D in the editor.
- **Player Controller** uses `CharacterBody3D` with mouse-look via `_input(InputEventMouseMotion)`.
- **Destructible items** implement a 4-phase health state machine. Fragments auto-delete after 5 s.
- **QA scripts** are standalone `.gd` files that can be attached to a Node in a test scene or run via `--script`.

### PETRR Workflow
Every stage follows: **Plan → Execute → Test → Review → Refine**.
QA Lead signs off before moving to the next stage.
