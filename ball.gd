extends CharacterBody2D

var win_size : Vector2
const START_SPEED : int = 500
const ACCEL : int = 50
var speed : int
var dir : Vector2
const MAX_Y_VECTOR : float = 0.6

var invulnerable_to = null
var invuln_timer := 0.0
const INVULN_DURATION := 0.4

const SLING_LAUNCH_BONUS := 1300

var held := false
var held_by = null
var held_charging := false
var held_charge_time := 0.0
var held_timer := 0.0

const HELD_TIMEOUT := 5.0
const HELD_OFFSET := 60.0
const SERVE_MAX_CHARGE_TIME := 1.4
const SERVE_MAX_HOLD_TIME := 3.0
const SERVE_CONTACT_RANGE := 40.0

@onready var hit_sound: AudioStreamPlayer = $HitSound

func _ready():
	await get_tree().process_frame
	win_size = get_viewport_rect().size

func new_ball(serve_dir_x := 0):
	position.x = win_size.x / 2
	position.y = randi_range(200, win_size.y - 200)
	speed = START_SPEED
	dir = random_direction(serve_dir_x)
	invulnerable_to = null
	invuln_timer = 0.0
	held = false
	held_by = null
	held_charging = false

func start_held_serve(paddle) -> void:
	held = true
	held_by = paddle
	held_charging = false
	held_charge_time = 0.0
	held_timer = HELD_TIMEOUT
	invulnerable_to = null
	invuln_timer = 0.0
	speed = 0
	if paddle.has_method("reset_charge_state"):
		paddle.reset_charge_state()
	position.y = paddle.position.y
	position.x = paddle.position.x + paddle.sling_direction * HELD_OFFSET

func _physics_process(delta):
	if held:
		_process_held(delta)
		return

	if invuln_timer > 0.0:
		invuln_timer -= delta
		if invuln_timer <= 0.0:
			invulnerable_to = null

	var collision = move_and_collide(dir * speed * delta)
	if collision:
		var collider = collision.get_collider()
		if collider == $"../Player1" or collider == $"../Player2":
			if collider != invulnerable_to:
				if collider.slinging and collider.sling_phase == "out":
					collider.sling_phase = "return"
					var dist = abs(collider.original_x - collider.position.x)
					collider.sling_speed = dist / collider.SLING_RETURN_TIME
					apply_sling_hit(collider, collider.current_charge_fraction)
				else:
					register_hit(collider)
			else:
				dir = dir.bounce(collision.get_normal())
				hit_sound.play()
		else:
			dir = dir.bounce(collision.get_normal())
			hit_sound.play()

func _process_held(delta: float) -> void:
	held_timer -= delta
	if not held_charging:
		position.y = held_by.position.y
		position.x = held_by.position.x + held_by.sling_direction * HELD_OFFSET
	if held_timer <= 0.0:
		launch_random_from_holder(held_by)

func launch_random_from_holder(paddle) -> void:
	if not held or held_by != paddle:
		return
	held = false
	held_by = null
	held_charging = false
	speed = START_SPEED
	var new_dir := Vector2()
	new_dir.x = paddle.sling_direction
	new_dir.y = randf_range(-1, 1)
	dir = new_dir.normalized()
	invulnerable_to = paddle
	invuln_timer = INVULN_DURATION

func start_charge(paddle) -> void:
	if not held or held_by != paddle or held_charging:
		return
	held_charging = true
	held_charge_time = 0.0

func update_charge(paddle, delta: float) -> void:
	if not held or held_by != paddle or not held_charging:
		return
	held_charge_time += delta
	if held_charge_time >= SERVE_MAX_HOLD_TIME:
		release_charge(paddle)

func release_charge(paddle) -> void:
	if not held or held_by != paddle or not held_charging:
		return
	var dist = position.y - paddle.position.y
	if abs(dist) > SERVE_CONTACT_RANGE:
		held_charging = false
		return
	var charge_fraction = min(held_charge_time / SERVE_MAX_CHARGE_TIME, 1.0)
	var new_dir := Vector2()
	new_dir.x = paddle.sling_direction
	new_dir.y = (dist / (paddle.p_height / 2)) * MAX_Y_VECTOR
	dir = new_dir.normalized()
	speed = START_SPEED + SLING_LAUNCH_BONUS * charge_fraction
	held = false
	held_by = null
	held_charging = false
	invulnerable_to = paddle
	invuln_timer = INVULN_DURATION

func register_hit(collider) -> void:
	speed += ACCEL
	dir = new_direction(collider)
	invulnerable_to = collider
	invuln_timer = INVULN_DURATION
	hit_sound.play()

func random_direction(x_override := 0):
	var new_dir := Vector2()
	if x_override != 0:
		new_dir.x = x_override
	else:
		new_dir.x = [1, -1].pick_random()
	new_dir.y = randf_range(-1, 1)
	return new_dir.normalized()

func new_direction(collider):
	var ball_y = position.y
	var pad_y = collider.position.y
	var dist = ball_y - pad_y
	var new_dir := Vector2()
	if collider == $"../Player1":
		new_dir.x = 1
	else:
		new_dir.x = -1
	new_dir.y = (dist / (collider.p_height / 2)) * MAX_Y_VECTOR
	return new_dir.normalized()

func apply_sling_hit(paddle, charge_fraction: float) -> void:
	if paddle == invulnerable_to:
		return
	var pad_y = paddle.position.y
	var dist = position.y - pad_y
	var new_dir := Vector2()
	new_dir.x = paddle.sling_direction
	new_dir.y = (dist / (paddle.p_height / 2)) * MAX_Y_VECTOR
	dir = new_dir.normalized()
	var sling_speed_result = START_SPEED + SLING_LAUNCH_BONUS * charge_fraction
	speed = max(speed + ACCEL, sling_speed_result)
	invulnerable_to = paddle
	invuln_timer = INVULN_DURATION
	hit_sound.play()

func _on_hitbox_body_entered(body, paddle) -> void:
	if body != self:
		return
	if paddle == invulnerable_to:
		return
	if paddle.slinging:
		apply_sling_hit(paddle, paddle.current_charge_fraction)
	else:
		register_hit(paddle)
