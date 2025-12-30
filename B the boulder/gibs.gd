extends RigidBody2D

@export var lifetime := 100.0       # seconds before gib disappears
@export var spawn_impulse := 200.0
@export var torque_impulse := 100.0  # optional spin

@onready var particles: CPUParticles2D = $CPUParticles2D  # child node, exact name

func _ready():
	# Random rotation
	rotation_degrees = randf_range(0, 360)

	# Randomize particle lifetime per instance
	if particles:
		var mat = particles.material
		if mat is ParticleProcessMaterial:
			mat.lifetime = randf_range(5, 15)  # per-gib lifetime
			mat.lifetime_randomness = 0.5       # ±50% randomness per particle
		particles.emitting = true
	else:
		push_error("CPUParticles2D not found!")

	# Apply small random movement
	var dir := Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, -0.2)
	).normalized()
	apply_impulse(dir * spawn_impulse)

	# Apply a little spin
	apply_torque_impulse(randf_range(-torque_impulse, torque_impulse))

	# Lifetime cleanup for the gib only
	await get_tree().create_timer(lifetime).timeout
	queue_free()
