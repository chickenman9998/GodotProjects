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

var npc_type: int = 0

var direction := 0
var timer := 0.0
var is_idle := true
var time := randf() * 10.0
var sprite_start_y := 0.0
var dead := false

var knockback: Vector2 = Vector2.ZERO
var knockback_scale := 2

func _ready():
	#pick character
	rng.randomize()
	sprite_start_y = sprite.position.y
	pick_character()
	_pick_new_state()
	$HazardDetector.monitoring = true


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

	floor_snap_length = 5
	move_and_slide()

	# EDGE detection (correct logic)
	if direction != 0 and not edge_ray.is_colliding() and not is_idle and knockback.length() <= 1.0:
		print("turning around (edge)")
		_turn_around()
	# Timer
	timer -= delta
	if timer <= 0:
		_pick_new_state()
	
	if direction != 0 and wall_ray.is_colliding() and not is_idle and knockback.length() <= 1.0: _turn_around()
	


	if Input.is_action_just_pressed("test"):
		die(100, npc_type)

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

	# allow raycast to update after flipping
	await get_tree().process_frame

	# if the new direction is ALSO blocked → squished
	if wall_ray.is_colliding():
		die(1, npc_type)
		return

	timer = randf_range(0.8, 2.0)



func die(speed: float, npc_type: int) -> void:
	if dead:
		return
		
	dead = true
	$HazardDetector.monitoring = false

	var gibs_scene: PackedScene = preload("res://gibs.tscn")

	# Preload one gib to inspect its sprite frame count
	var temp_gib: Node2D = gibs_scene.instantiate()
	var rigid_temp: RigidBody2D = temp_gib.get_node("RigidBody2D")
	var gib_sprite_temp: AnimatedSprite2D = rigid_temp.get_node_or_null("AnimatedSprite2D")

	var frame_count := gib_sprite_temp.sprite_frames.get_frame_count(str(npc_type)) if gib_sprite_temp else 0
	#print(str(npc_type))
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
				gib_sprite.animation = str(npc_type)
				gib_sprite.frame = frames[i % frame_count]
				
		get_tree().current_scene.call_deferred("add_child", gibs)

	# Remove the NPC
	queue_free()
func _on_hazard_detector_body_entered(body: Node2D) -> void:
	if body is RigidBody2D:
		#linear + rotational speed
		var speed = int(body.linear_velocity.length()) / 10
		var rot_speed = int(abs(body.angular_velocity)) * 10
		var total_motion = speed + rot_speed
		var standing_on := edge_ray.get_collider()

		var slide_collision = get_last_slide_collision()

		# Directional hit detection (original)
		var hit_from_above := slide_collision and slide_collision.get_normal().y > 0.7
		var hit_from_below := slide_collision and slide_collision.get_normal().y < -0.7
		var hit_from_side = slide_collision and abs(slide_collision.get_normal().x) > 0.7

		# -------------------------------
		# NEW: fallback when slide_collision is null
		# -------------------------------
		if slide_collision == null:
			hit_from_above = body.global_position.y < global_position.y - 4
			hit_from_below = body.global_position.y > global_position.y + 4
			hit_from_side = abs(body.global_position.x - global_position.x) < 6
		# -------------------------------

		if standing_on == body:
			print("BUMPED Upwards")
			apply_knockback_from(body)
			return

		# Boulder special case
		elif body.name == "boulder" and total_motion > 90:
			print("RUN OVER by boulder: ", total_motion)
			die(total_motion, npc_type)
			return

		# CRUSH CHECK — now uses hit_from_above
		elif standing_on != null and hit_from_above:
			print("CRUSHED by falling object")
			die(total_motion * 0.5, npc_type)
			return

		# High‑velocity hazard — now requires side or below hit
		elif (body.is_in_group("Hazard") and (speed > 90 or rot_speed > 30)) and body.name != "boulder" and (hit_from_side or hit_from_below):
			print("KILLED by high velocity object:", total_motion)
			die(speed, npc_type)
			return
			
		elif hit_from_side:
			print("KNOCKBACK:", total_motion)
			apply_knockback_from(body)
			return

		else:
			print("KNOCKBACK (fallback):", total_motion)
			apply_knockback_from(body)
			return



func apply_knockback_from(body: Node2D) -> void:
	# Use the rigid body's actual velocity
	knockback = body.linear_velocity * knockback_scale

	# Prevent downward tunneling through thin floors
	if knockback.y > 0 and is_on_floor():
		knockback.y = 0

	# Ignore collisions with this body during knockback
	add_collision_exception_with(body)

func pick_character() -> void:
	var char_selection := "npc_characters"
	var frame_count := sprite.sprite_frames.get_frame_count(char_selection)
	if frame_count <= 0:
		print("no sprite frames")
		return
	# Pick a random frame
	#npc_type = rng.randi_range(0, frame_count - 1)
	npc_type = rng.randi_range(0, 2)
	sprite.animation = char_selection
	sprite.frame = npc_type
