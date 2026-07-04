extends CharacterBody3D

## WWJMD Player Controller — 3D FPS Mouse-Look
## Stage 1: Gameplay Engineer

@export var mouse_sensitivity: float = 0.002
@export var move_speed: float = 5.0
@export var sprint_multiplier: float = 1.5
@export var acceleration: float = 12.0
@export var jump_speed: float = 4.5
@export var shot_damage: float = 10.0
@export var shot_range: float = 100.0

var _camera: Camera3D
var _input_dir: Vector2
var _is_sprinting: bool = false
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

signal shot_fired(hit_point: Vector3, hit_node: Node)

func _ready():
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_camera = $Camera3D as Camera3D
	assert(_camera != null, "Player must have a Camera3D child named 'Camera3D'")

func _input(event: InputEvent):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var look_yaw = -event.relative.x * mouse_sensitivity
		var look_pitch = -event.relative.y * mouse_sensitivity
		_camera.rotation.x = clamp(_camera.rotation.x + look_pitch, -1.4, 1.4)
		rotate_y(look_yaw)
	elif event.is_action_pressed("ui_cancel"):
		# Escape releases the mouse so the player can reach the window/UI
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventMouseButton and event.pressed:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			# Click recaptures; swallow it so it doesn't also fire a shot
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent):
	# Shooting lives in unhandled input so UI clicks and the
	# mouse-recapture click never double as shots
	if event.is_action_pressed("shoot") and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_shoot()

func _physics_process(delta: float):
	_input_dir = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	)

	_is_sprinting = Input.is_action_pressed("sprint")

	var speed = move_speed * (sprint_multiplier if _is_sprinting else 1.0)
	var target_velocity = Vector3.ZERO
	if _input_dir.length() > 0.1:
		var forward = -global_transform.basis.z
		var right = global_transform.basis.x
		target_velocity = (forward * _input_dir.y + right * _input_dir.x).normalized() * speed

	# Apply acceleration (lerp weight clamped to prevent overshoot)
	var h_vel = Vector3(velocity.x, 0, velocity.z)
	var weight = clamp(delta * acceleration, 0.0, 1.0)
	h_vel = h_vel.lerp(target_velocity, weight)
	velocity.x = h_vel.x
	velocity.z = h_vel.z

	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_speed
	else:
		velocity.y -= _gravity * delta

	move_and_slide()

func _shoot() -> void:
	var from = _camera.global_position
	var to = from + (-_camera.global_transform.basis.z) * shot_range
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return

	var hit: Node = result["collider"]
	shot_fired.emit(result["position"], hit)

	# Route damage to the nearest ancestor that understands it
	var node: Node = hit
	while node:
		if node.has_method("apply_damage"):
			node.apply_damage(shot_damage)
			return
		node = node.get_parent()
