extends CPUParticles2D

@export var lifetime_sec := 0.5
@export var amount_particles := 50
@export var speed_min := 150.0
@export var speed_max := 400.0
@export var gravity_vec := Vector2(0, 800)
@export var scale_vec := Vector2(0.5, 0.5)
@export var spread_angle := 360  # degrees

func _ready():
	emitting = false
	one_shot = true
	lifetime = lifetime_sec
	amount = amount_particles

	# Create particle material
	var mat := CPUParticles2D.new()
	
	# Random initial velocity range
	mat.initial_velocity = (speed_min + speed_max) / 2
	mat.velocity_random = 1.0  # randomize direction
	mat.angle = 0
	mat.angle_random = spread_angle / 360.0  # full circle spread
	mat.gravity = gravity_vec
	mat.scale = scale_vec
	mat.lifetime_randomness = 0.3

	# Emit
	emitting = true

	# Remove after lifetime
	await get_tree().create_timer(lifetime_sec).timeout
	queue_free()
