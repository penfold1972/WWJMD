extends RigidBody3D

## WWJMD Destructible Item — 4-Phase Health State Machine
## Stage 2: Gameplay Engineer
##
## Physics: items spawn frozen (they behave as static scenery, which keeps
## hundreds of them cheap). When one is destroyed it "blasts" nearby items in
## the "snacks" group — those unfreeze, take an impulse, and become live
## rigid bodies that can slide around or fall off the shelf.

enum Phase {
	INDESTRUCTIBLE,   # Phase 1 — absorbs hits
	DENT,             # Phase 2 — mesh distortion / local scaling
	DAMAGED,          # Phase 3 — particle spawn, mirror variant
	DESTROYED         # Phase 4 — fragment cluster, queue_free
}

const FRAGMENT_LIFETIME: float = 5.0

@export var brand_data: Resource = null
@export var max_health: float = 100.0
@export var dent_threshold: float = 75.0
@export var damaged_threshold: float = 40.0
@export var is_mirror_variant: bool = false
@export var fragment_count: int = 12
@export var fragment_scene: PackedScene = null
@export var particle_debris: PackedScene = null
@export var particle_liquid: PackedScene = null
@export var explosion_radius: float = 0.7
@export var explosion_impulse: float = 1.2

var _current_phase: int = Phase.INDESTRUCTIBLE
var _health: float
var _mesh_instance: MeshInstance3D
var _original_scale: Vector3
# Unused — reserved for future vertex-deformation dent system

signal phase_changed(from_phase: int, to_phase: int)
signal destroyed()
signal collected()

func _ready():
	_health = max_health
	freeze = true
	add_to_group("snacks")
	_mesh_instance = $MeshInstance3D as MeshInstance3D
	assert(_mesh_instance != null, "DestructibleItem requires a MeshInstance3D child")
	_original_scale = _mesh_instance.scale

func collect() -> void:
	# Picked up intact by the player — no fragments, no debris
	if _current_phase == Phase.DESTROYED:
		return
	_current_phase = Phase.DESTROYED
	collected.emit()
	queue_free()

func apply_damage(amount: float) -> void:
	if _current_phase == Phase.DESTROYED:
		return

	_health -= amount
	_health = max(_health, 0.0)

	var new_phase = _current_phase
	if _health > dent_threshold:
		new_phase = Phase.INDESTRUCTIBLE
	elif _health > damaged_threshold:
		new_phase = Phase.DENT
	elif _health > 0.0:
		new_phase = Phase.DAMAGED
	else:
		new_phase = Phase.DESTROYED

	if new_phase != _current_phase:
		var old = _current_phase
		_current_phase = new_phase
		_enter_phase(new_phase)
		phase_changed.emit(old, new_phase)

func _enter_phase(phase: int) -> void:
	match phase:
		Phase.DENT:
			_apply_dent()
		Phase.DAMAGED:
			_apply_damaged()
		Phase.DESTROYED:
			_apply_destroyed()

func _apply_dent() -> void:
	# Distort mesh with slight local scaling deformation
	if _mesh_instance:
		var dent = Vector3(
			randf_range(0.92, 0.98),
			randf_range(0.95, 1.0),
			randf_range(0.92, 0.98)
		)
		_mesh_instance.scale = _original_scale * dent

func _apply_damaged() -> void:
	# Reset scale and spawn appropriate particles
	_mesh_instance.scale = _original_scale

	var container = "box"
	if brand_data:
		var cls = brand_data.get("container_class")
		container = cls if cls is String else "box"

	match container:
		"can", "bottle":
			_spawn_particles(particle_liquid)
		_:
			_spawn_particles(particle_debris)

func blast(from: Vector3, strength: float) -> void:
	# Shockwave from a neighboring item's destruction: go live and take a shove
	if _current_phase == Phase.DESTROYED:
		return
	freeze = false
	sleeping = false
	var dir = (global_position - from + Vector3(0, 0.15, 0)).normalized()
	apply_central_impulse(dir * strength)

func _blast_neighbors() -> void:
	for node in get_tree().get_nodes_in_group("snacks"):
		if node == self or not is_instance_valid(node):
			continue
		var dist = node.global_position.distance_to(global_position)
		if dist < explosion_radius:
			var falloff = 1.0 - dist / explosion_radius
			node.blast(global_position, explosion_impulse * (0.4 + falloff))

func _apply_destroyed() -> void:
	# Spawn fragment cluster, shove the neighbors, and remove self
	if _mesh_instance:
		_mesh_instance.visible = false

	# Stop colliding immediately so blasted neighbors don't bounce off the corpse
	collision_layer = 0
	collision_mask = 0

	_blast_neighbors()
	_spawn_fragments()

	# Queue self after fragments are emitted
	var timer := get_tree().create_timer(0.1)
	timer.timeout.connect(_remove_self)

func _remove_self() -> void:
	destroyed.emit()
	queue_free()

func _spawn_particles(scene: PackedScene) -> void:
	if scene == null:
		return
	var particles = scene.instantiate() as GPUParticles3D
	if particles == null:
		return
	# Reparent to world root so particles survive the item's destruction
	var world = get_tree().root
	world.add_child(particles)
	particles.global_transform.origin = global_transform.origin
	particles.emitting = true
	particles.one_shot = true
	# Self-clean particles after they finish (duration + max particle lifetime)
	var cleanup_time = particles.duration + particles.lifetime * 1.5
	var t = get_tree().create_timer(cleanup_time)
	t.timeout.connect(func(): particles.queue_free())

func _spawn_fragments() -> void:
	var parent = get_parent()
	if parent == null:
		return

	for i in fragment_count:
		var frag: Node3D
		if fragment_scene:
			frag = fragment_scene.instantiate() as Node3D
		else:
			# Fallback: simple RigidBody3D cube
			frag = RigidBody3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(0.08, 0.08, 0.08) * randf_range(0.5, 1.5)
			var col = CollisionShape3D.new()
			col.shape = box
			frag.add_child(col)
			var mesh = MeshInstance3D.new()
			var bm = BoxMesh.new()
			bm.size = box.size
			mesh.mesh = bm
			frag.add_child(mesh)

		parent.add_child(frag)
		frag.global_transform.origin = global_transform.origin + Vector3(
			randf_range(-0.2, 0.2),
			randf_range(0.0, 0.3),
			randf_range(-0.2, 0.2)
		)

		if frag is RigidBody3D:
			var dir = Vector3(
				randf_range(-1.0, 1.0),
				randf_range(0.0, 1.0),
				randf_range(-1.0, 1.0)
			).normalized() * randf_range(3.0, 8.0)
			frag.linear_velocity = dir

		# Auto-delete after FRAGMENT_LIFETIME
		var lifetime = FRAGMENT_LIFETIME * randf_range(0.8, 1.2)
		var t = get_tree().create_timer(lifetime)
		t.timeout.connect(func(): frag.queue_free())
