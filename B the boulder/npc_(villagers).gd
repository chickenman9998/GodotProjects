extends CharacterBody2D

# --- MOVEMENT ---
@export var walk_speed := 20.0
@export var walk_time := Vector2(1.5, 4.0)
@export var idle_time := Vector2(0.5, 2.0)
@export var gravity := 800.0

# --- WOBBLE ---
@export var wobble_rotation := 1.2
@export var wobble_height := 1.0
@export var wobble_speed := 1.2

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var direction := 0
var timer := 0.0
var is_idle := true
var time := randf() * 10.0
var sprite_start_y := 0.0

func _ready():
	# Pick random character frame ONCE
	sprite.animation = "characters"
	var frame_count := sprite.sprite_frames.get_frame_count("characters")
	if frame_count > 0:
		sprite.frame = randi() % frame_count
	sprite.playing = false

	sprite_start_y = sprite.position.y
	_pick_new_state()

func _physics_process(delta):
	time += delta * wobble_speed

	# --- WOBBLE ---
	sprite.rotation_degrees = sin(time) * wobble_rotation
	sprite.position.y = sprite_start_y + round(sin(time * 1.3) * wobble_height)

	# --- GRAVITY ---
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# --- HORIZONTAL MOVE ---
	if not is_idle:
		velocity.x = direction * walk_speed
	else:
		velocity.x = 0

	move_and_slide()

	# --- STATE TIMER ---
	timer -= delta
	if timer <= 0:
		_pick_new_state()

func _pick_new_state():
	is_idle = randf() < 0.4

	if is_idle:
		timer = randf_range(idle_time.x, idle_time.y)
		direction = 0
	else:
		timer = randf_range(walk_time.x, walk_time.y)
		direction = [-1, 1].pick_random()
		sprite.flip_h = direction < 0
