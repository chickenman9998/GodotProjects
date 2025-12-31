extends CharacterBody2D
class_name NPC

var rng = RandomNumberGenerator.new()

@export var walk_speed := 40
@export var walk_time := Vector2(1.5, 4.0)
@export var idle_time := Vector2(0.5, 2.0)
@export var gravity := 800

@export var wobble_rotation := 5
@export var wobble_height := 1
@export var wobble_speed := 30

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var edge_ray: RayCast2D = $RayCast2D

var direction := 0
var timer := 0.0
var is_idle := true
var time := randf() * 10.0
var sprite_start_y := 0.0
var dead := false

func _ready():
	rng.randomize()
	sprite_start_y = sprite.position.y
	_pick_new_state()

func _physics_process(delta):
	if dead:
		return

	# Wobble animation
	if not is_idle:
		time += delta * wobble_speed
		sprite.rotation_degrees = sin(time) * wobble_rotation
		sprite.position.y = sprite_start_y + sin(time * 1.3) * wobble_height
	else:
		sprite.rotation_degrees = 0
		sprite.position.y = sprite_start_y

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		is_idle = true
	else:
		velocity.y = 0

	# Horizontal movement
	velocity.x = direction * walk_speed if not is_idle else 0

	# Edge detection
	if direction != 0 and edge_ray and not edge_ray.is_colliding():
		_turn_around()

	# Timer
	timer -= delta
	if timer <= 0:
		_pick_new_state()

	move_and_slide()

	if Input.is_action_just_pressed("test"):
		die()

func _pick_new_state():
	is_idle = randf() < 0.4

	if is_idle:
		timer = randf_range(idle_time.x, idle_time.y)
		direction = 0
	else:
		timer = randf_range(walk_time.x, walk_time.y)
		direction = [-1, 1].pick_random()
		sprite.flip_h = direction > 0
		edge_ray.target_position.x = abs(edge_ray.target_position.x) * direction

func _turn_around():
	direction *= -1
	sprite.flip_h = direction > 0
	edge_ray.target_position.x = abs(edge_ray.target_position.x) * direction
	timer = randf_range(0.8, 2.0)

func die():
	if dead:
		return
	dead = true

	var gibs_scene: PackedScene = preload("res://Gibs.tscn")
	var temp_gib: Node2D = gibs_scene.instantiate()
	var rigid_temp: RigidBody2D = temp_gib.get_node("RigidBody2D")
	var gib_sprite_temp: AnimatedSprite2D = rigid_temp.get_node_or_null("AnimatedSprite2D")

	var frame_count := gib_sprite_temp.sprite_frames.get_frame_count("gib_bits") if gib_sprite_temp else 0

	var frames: Array = []
	for f in frame_count:
		frames.append(f)
	frames.shuffle()

	for i in 5:
		var gibs: Node2D = gibs_scene.instantiate()
		gibs.global_position = global_position

		var rigid: RigidBody2D = gibs.get_node("RigidBody2D")
		if rigid:
			var gib_sprite: AnimatedSprite2D = rigid.get_node_or_null("AnimatedSprite2D")
			if gib_sprite and frame_count > 0:
				gib_sprite.frame = frames[i % frame_count]

		get_tree().current_scene.call_deferred("add_child", gibs)

	queue_free()


func _on_hazard_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("Hazard"):
		var speed := 0
		if body is RigidBody2D:
			speed = int(body.linear_velocity.length()) / 10
		if speed > 20:
			print(speed)
			die()
		else:
			print(speed)
