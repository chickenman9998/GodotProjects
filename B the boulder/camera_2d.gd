extends Camera2D

@export var follow_speed := 6
@export var horizontal_scale := 0.2     # how much horizontal speed affects camera
@export var vertical_scale := 0.05      # how much vertical speed affects camera (reduced)

var target: RigidBody2D

func _ready():
	target = get_parent()

func _process(delta):
	if not target:
		return

	var vel := target.linear_velocity

	# Momentum-based offset
	var desired_offset := Vector2(
		vel.x * horizontal_scale,
		-vel.y * vertical_scale   # reduced vertical influence
	)

	# Smooth camera movement
	offset = offset.lerp(desired_offset, delta * follow_speed)
