extends RigidBody2D

@export var lifetime := 15      # seconds before gib disappears

## to give characters an explosion effect add mask layer 6 to boulder (will add explosi
## insanely high impulse, but being crushed by boulder, therefore gibs wont go too far. compare to T kill function
@export var torque_impulse := 300  # optional spin

@onready var particles: CPUParticles2D = $InitialBloodSplatter  # child node, exact name
@onready var particleslinger: CPUParticles2D = $LingeringBlood
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D  # fade this instead of scaling

@export var spawn_impulse := 0   # THIS is the only correct declaration DO NOT TOUCH

func set_spawn_impulse(value: int) -> void:
	spawn_impulse = value * 4 # =multiply spawn impulse

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

	particleslinger.emitting = true

	# Apply small random movement
	var dir := Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, -0.2)
	).normalized()

	#print(spawn_impulse)
	apply_impulse(dir * spawn_impulse)

	# Apply a little spin
	apply_torque_impulse(randf_range(-torque_impulse, torque_impulse))

	# Start fade-out after lifetime
	fade_after_lifetime()


func fade_after_lifetime() -> void:
	# Wait the full lifetime first
	await get_tree().create_timer(lifetime).timeout

	if linear_velocity.length() < 5 and abs(angular_velocity) < 1:
		sleeping = true

	# Fade out in 50 steps
	for i in 100:
		var c := sprite.modulate
		c.a -= 0.01  # reduce opacity
		sprite.modulate = c

		await get_tree().create_timer(0.05).timeout  # delay between steps

	queue_free()
