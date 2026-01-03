extends Node2D

@onready var body: RigidBody2D = $cannon_body

@export var launch_force := 1000
@export var launch_angle_degrees := -5
@export var spin_impulse := 5000   # rotational impulse on launch

func _ready() -> void:
	# Instead of freezing/sleeping, give it a constant rotation
	body.angular_velocity = 25

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("test_two"):
		launch()

func launch() -> void:
	# Stop the idle rotation when firing
	body.angular_velocity = 0

	var angle := deg_to_rad(launch_angle_degrees)
	var dir := Vector2.RIGHT.rotated(angle)

	# Linear impulse
	body.apply_impulse(dir * launch_force)

	# Rotational impulse (spin after firing)
	body.apply_torque_impulse(spin_impulse)
