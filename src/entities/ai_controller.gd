extends CharacterBody3D

## WWJMD AI Controller — Navmesh-driven civilian/cop placeholder
## Stage 4: Gameplay Engineer

enum AIState {
	IDLE,
	ALERT,
	CHASE,
	ATTACK
}

@export var aggro_radius: float = 12.0
@export var visibility_angle: float = 55.0  # degrees from facing direction
@export var move_speed: float = 2.5
@export var chase_speed: float = 4.0
@export var health: float = 50.0
@export var ai_label: String = "civilian"

var _state: int = AIState.IDLE
var _player_ref: Node3D = null
var _nav_agent: NavigationAgent3D = null
var _origin: Vector3
# Unused — reserved for future movement smoothing

signal ai_state_changed(from_state: int, to_state: int)

func _ready():
	_nav_agent = $NavigationAgent3D as NavigationAgent3D
	assert(_nav_agent != null, "AI requires a NavigationAgent3D child")
	_nav_agent.target_position = global_transform.origin
	_origin = global_transform.origin

func setup(player: Node3D) -> void:
	_player_ref = player

func _physics_process(delta: float):
	if _player_ref == null:
		return

	var dist = global_transform.origin.distance_to(_player_ref.global_transform.origin)

	match _state:
		AIState.IDLE:
			_handle_idle(dist)
		AIState.ALERT:
			_handle_alert(dist)
		AIState.CHASE:
			_handle_chase(delta)
		AIState.ATTACK:
			_handle_attack(delta)

func _handle_idle(dist: float) -> void:
	if dist < aggro_radius and _is_in_view_cone():
		_change_state(AIState.ALERT)

func _handle_alert(dist: float) -> void:
	# Face player, play alert, then chase
	if dist < aggro_radius * 1.5:
		_change_state(AIState.CHASE)
	else:
		_change_state(AIState.IDLE)

func _handle_chase(delta: float) -> void:
	if _nav_agent.is_target_reached():
		_change_state(AIState.ATTACK)
		return

	_nav_agent.target_position = _player_ref.global_transform.origin

	var next_pos = _nav_agent.get_next_path_position()
	var dir = (next_pos - global_transform.origin).normalized()
	var speed = chase_speed

	velocity = dir * speed
	move_and_slide()

	# If player moves out of aggro, return to origin
	var dist = global_transform.origin.distance_to(_player_ref.global_transform.origin)
	if dist > aggro_radius * 2.0:
		_change_state(AIState.IDLE)
		_nav_agent.target_position = _origin

func _handle_attack(_delta: float) -> void:
	# Placeholder: face player and emit alert
	look_at(_player_ref.global_transform.origin, Vector3.UP)
	var dist = global_transform.origin.distance_to(_player_ref.global_transform.origin)
	if dist > aggro_radius * 1.5:
		_change_state(AIState.CHASE)

func _is_in_view_cone() -> bool:
	if _player_ref == null:
		return false
	var to_player = (_player_ref.global_transform.origin - global_transform.origin).normalized()
	var facing = -global_transform.basis.z
	var dot = to_player.dot(facing)
	var angle_rad = acos(clamp(dot, -1.0, 1.0))
	return rad_to_deg(angle_rad) < visibility_angle * 0.5

func _change_state(new_state: int) -> void:
	var old = _state
	_state = new_state
	ai_state_changed.emit(old, new_state)
