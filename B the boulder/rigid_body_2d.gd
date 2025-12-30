extends RigidBody2D

@export var torque_force := 0
@export var jump_impulse := 0


@onready var ground_ray: RayCast2D = get_node_or_null("GroundRay")

func _physics_process(_delta):
	# Rotate boulder
	if Input.is_action_pressed("move_right"):
		if ground_ray.is_colliding():
			apply_torque(torque_force * 15000)
		else:
			apply_torque(torque_force * 3750)
	elif Input.is_action_pressed("move_left"):
		if ground_ray.is_colliding():
			apply_torque(-torque_force * 15000)
		else:
			apply_torque(-torque_force * 3750)

	# Jump
	if Input.is_action_just_pressed("jump") and ground_ray != null and ground_ray.is_colliding():
		apply_impulse(Vector2(0, -jump_impulse*1000))
		print("Jumped!")
	elif Input.is_action_just_pressed("jump"):
		print("Cannot jump. Grounded =", ground_ray != null and ground_ray.is_colliding())
