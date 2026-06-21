extends CharacterBody3D

## WWJMD Player Controller — 3D FPS Mouse-Look
## Stage 1: Gameplay Engineer

@export var mouse_sensitivity: float = 0.002
@export var move_speed: float = 5.0
@export var sprint_multiplier: float = 1.5
@export var acceleration: float = 12.0
@export var friction: float = 0.85  # unused; kept for tuning API

var _camera: Camera3D
var _input_dir: Vector2
var _is_sprinting: bool = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_camera = $Camera3D as Camera3D
	assert(_camera != null, "Player must have a Camera3D child named 'Camera3D'")

func _input(event: InputEvent):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var look_yaw = -event.relative.x * mouse_sensitivity
		var look_pitch = -event.relative.y * mouse_sensitivity
		_camera.rotation.x = clamp(_camera.rotation.x + look_pitch, -1.4, 1.4)
		rotate_y(look_yaw)

func _process(_delta: float):
	# Capture mouse on any click when UI is visible
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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

	move_and_slide()
