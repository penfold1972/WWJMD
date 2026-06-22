extends Node

## WWJMD Game Manager — Root game loop
## Builds the level, spawns player + AI, wires exit trigger to end screen

@export var player_scene: PackedScene = null
@export var enemy_template: PackedScene = null
@export var player_spawn_position: Vector3 = Vector3(0, 0, 4)

var _level_builder: Node3D
var _player: CharacterBody3D

func _ready():
	_build_level()
	_spawn_player()
	_connect_exit_trigger()

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
	if player_scene == null:
		push_warning("GameManager: no player_scene assigned — creating default CharacterBody3D")
		var body = CharacterBody3D.new()
		var cam = Camera3D.new()
		cam.name = "Camera3D"
		body.add_child(cam)
		var pc = preload("res://src/entities/player_controller.gd")
		body.set_script(pc)
		_player = body
	else:
		_player = player_scene.instantiate() as CharacterBody3D

	_player.name = "Player"
	_player.global_transform.origin = player_spawn_position
	add_child(_player)

func _connect_exit_trigger() -> void:
	# The level builder emits level_exit_triggered when the player reaches the van
	var exit_signal = _level_builder.level_exit_triggered
	exit_signal.connect(_on_level_exit)

func _on_level_exit() -> void:
	print("GameManager: level exit triggered — showing end screen")
	var end_script = preload("res://src/ui/end_screen.gd")
	var end_screen = end_script.new() as CanvasLayer
	add_child(end_screen)
	end_screen.build_ui()
