extends Node

## WWJMD Game Manager — Root game loop
## Builds the level, spawns player + AI, wires exit trigger to end screen

@export var player_scene: PackedScene = preload("res://src/entities/player.tscn")
@export var enemy_template: PackedScene = null
@export var player_spawn_position: Vector3 = Vector3(0, 0.2, 4)

const FALL_RESET_Y: float = -10.0

var _level_builder: Node3D
var _player: CharacterBody3D
var _hud: CanvasLayer
var _level_complete: bool = false

func _ready():
	_build_level()
	_spawn_player()
	_build_hud()
	_connect_exit_trigger()

func _physics_process(_delta: float):
	# Safety net: walking off the parking lot edge respawns instead of falling forever
	if _player and _player.global_position.y < FALL_RESET_Y:
		_player.global_position = player_spawn_position
		_player.velocity = Vector3.ZERO

func _build_level() -> void:
	var builder_script = preload("res://src/core/level_builder.gd")
	_level_builder = builder_script.new() as Node3D
	_level_builder.name = "LevelBuilder"
	_level_builder.enemy_template = enemy_template
	_level_builder.civilian_count = 3
	_level_builder.cop_count = 2
	add_child(_level_builder)
	_level_builder.build_level()

func _spawn_player() -> void:
	_player = player_scene.instantiate() as CharacterBody3D
	_player.name = "Player"
	add_child(_player)
	_player.global_position = player_spawn_position

func _build_hud() -> void:
	var hud_script = preload("res://src/ui/hud.gd")
	_hud = hud_script.new() as CanvasLayer
	_hud.name = "HUD"
	add_child(_hud)
	_level_builder.snack_destroyed.connect(_hud.set_snack_count)

func _connect_exit_trigger() -> void:
	# The level builder emits level_exit_triggered when the player reaches the van
	_level_builder.level_exit_triggered.connect(_on_level_exit)

func _on_level_exit() -> void:
	if _level_complete:
		return
	_level_complete = true
	print("GameManager: level exit triggered — showing end screen")
	var end_script = preload("res://src/ui/end_screen.gd")
	var end_screen = end_script.new() as CanvasLayer
	add_child(end_screen)
	get_tree().paused = true
