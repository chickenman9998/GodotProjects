extends Node2D

@onready var body: RigidBody2D = $cannon_body

@export var launch_force := 500
@export var launch_angle_degrees := -10

func _ready() -> void:
	body.freeze = true
	body.sleeping = true


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("test_two"):
		launch()

func launch() -> void:
	body.freeze = false
	body.sleeping = false

	var angle := deg_to_rad(launch_angle_degrees)
	var dir := Vector2.RIGHT.rotated(angle)

	body.apply_impulse(dir * launch_force)
