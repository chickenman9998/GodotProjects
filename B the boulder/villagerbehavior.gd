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
@onready var edge_ray: RayCast2D = $FloorRaycast
@onready var wall_ray: RayCast2D = $WallRaycast
@onready var col: CollisionShape2D = $CollisionShape2D


var direction := 0
var timer := 0.0
var is_idle := true
var time := randf() * 10.0
var sprite_start_y := 0.0
var dead := false

var knockback: Vector2 = Vector2.ZERO
var knockback_scale := 2

var npc_type: int = 0

func _ready():
	rng.randomize()
	sprite_start_y = sprite.position.y
	pick_character() # random by default
	_pick_new_state()

	#pick character
	rng.randomize()
	sprite_start_y = sprite.position.y
	pick_character()
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

	#if function for knockback and else function for movement
	if knockback.length() > 1.0:
		velocity.x = knockback.x
		velocity.y += knockback.y * delta
		knockback = knockback.move_toward(Vector2.ZERO, 1500 * delta)
	else:
		# Re-enable collisions with all bodies we ignored
		for body in get_collision_exceptions():
			remove_collision_exception_with(body)

		velocity.x = direction * walk_speed if not is_idle else 0


	# EDGE detection (correct logic)
	if direction != 0 and not edge_ray.is_colliding() and not is_idle and knockback.length() <= 1.0:
		print("turning around (edge)")
		_turn_around()
	# Timer
	timer -= delta
	if timer <= 0:
		_pick_new_state()

	move_and_slide()

	if direction != 0 and wall_ray.is_colliding() and not is_idle and knockback.length() <= 1.0: _turn_around()

	if Input.is_action_just_pressed("test"):
		die(100, 1)

func _pick_new_state():
	is_idle = randf() < 0.4

	if is_idle:
		timer = randf_range(idle_time.x, idle_time.y)
		direction = 0
	else:
		timer = randf_range(walk_time.x, walk_time.y)
		direction = [-1, 1].pick_random()
		sprite.flip_h = direction > 0

		wall_ray.target_position.x = abs(wall_ray.target_position.x) * direction
		edge_ray.position.x = abs(edge_ray.position.x) * direction

func _turn_around():
	direction *= -1
	sprite.flip_h = direction > 0

	wall_ray.target_position.x = abs(wall_ray.target_position.x) * direction
	edge_ray.position.x = abs(edge_ray.position.x) * direction

	timer = randf_range(0.8, 2.0)



func die(speed: float, npc_type: int) -> void:
	if dead:
		return
	dead = true

	var gibs_scene: PackedScene = preload("res://Gibs.tscn")

	# Preload one gib to inspect its sprite frame count
	var temp_gib: Node2D = gibs_scene.instantiate()
	var rigid_temp: RigidBody2D = temp_gib.get_node("RigidBody2D")
	var gib_sprite_temp: AnimatedSprite2D = rigid_temp.get_node_or_null("AnimatedSprite2D")

	var frame_count := gib_sprite_temp.sprite_frames.get_frame_count("gib_bits") if gib_sprite_temp else 0

	# Shuffle frame order
	var frames: Array = []
	for f in frame_count:
		frames.append(f)
	frames.shuffle()

	# Spawn 5 gibs
	for i in 5:
		var gibs: Node2D = gibs_scene.instantiate()
		gibs.global_position = global_position

		# Get the RigidBody2D child (this is where set_spawn_impulse exists)
		var rigid: RigidBody2D = gibs.get_node("RigidBody2D")

		# Pass speed into the gib
		if rigid and rigid.has_method("set_spawn_impulse"):
			rigid.set_spawn_impulse(speed)

		# Assign random gib frame
		if rigid:
			var gib_sprite: AnimatedSprite2D = rigid.get_node_or_null("AnimatedSprite2D")
			if gib_sprite and frame_count > 0:
				gib_sprite.frame = frames[i % frame_count]

		# (placeholder) use npc_type later to pick different gib sets
		# match npc_type:
		#     0: gib_sprite.play("gib_bits")
		#     1: gib_sprite.play("gib_zombie")
		#     etc...

		get_tree().current_scene.call_deferred("add_child", gibs)

	# Remove the NPC
	queue_free()


func _on_hazard_detector_body_entered(body: Node2D) -> void:
	print(body)
	if body is RigidBody2D:
		var speed := 0
		speed = int(body.linear_velocity.length()) / 10
		if body.is_in_group("Hazard") and speed > 30:
			if body.name == "boulder": #boulder has double gib speed - looks better
				print("boulder death: ", speed)
				die(speed * 2, 1)
			else: 
				print("death: ", speed)
				die(speed, 1)
		else:
			print("push: ", speed)
			apply_knockback_from(body)
			

func apply_knockback_from(body: Node2D) -> void:
		# Use the rigid body's actual velocity
		knockback = body.linear_velocity * knockback_scale
		#print(body, "knockback: (", snapped(knockback.x, 0.01), ", ", snapped(knockback.y, 0.01), ")")

		# Ignore collisions with this body during knockback
		add_collision_exception_with(body)

func pick_character() -> void:
	var char_selection := "npc_characters"
	var frame_count := sprite.sprite_frames.get_frame_count(char_selection)
	if frame_count <= 0:
		print("no sprite frames")
		return

	# Pick a random frame
	npc_type = rng.randi_range(0, frame_count - 1)

	sprite.animation = char_selection
	sprite.frame = npc_type
	print(sprite.frame)
