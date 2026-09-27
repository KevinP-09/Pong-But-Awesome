extends CharacterBody2D

var win_height : int
var p_height : float

var win_width : int
var original_x : float
var center_x : float
var max_distance : float
var sling_direction : float
var charging := false
var charge_time := 0.0
var slinging := false
var sling_phase := ""
var sling_target_x : float
var sling_speed : float
var pause_timer := 0.0
var current_charge_fraction := 0.0
var ball_touching := false
var ball_ref = null

const MAX_CHARGE_TIME := 1.4
const MAX_HOLD_TIME := 3.0
const SLING_BUFFER := 20.0
const SLING_OUT_TIME := 0.15
const SLING_PAUSE_TIME := 0.2
const SLING_RETURN_TIME := 0.2
const WINDUP_DISTANCE := 15.0

func _ready() -> void:
	win_height = get_viewport_rect().size.y
	win_width = get_viewport_rect().size.x
	p_height = $ColorRect.size.y
	original_x = position.x
	center_x = win_width / 2.0
	sling_direction = sign(center_x - original_x)
	print(name, " sling_direction: ", sling_direction, " position.x: ", position.x, " p_height: ", p_height)
	max_distance = (abs(center_x - original_x) - SLING_BUFFER) * 0.8
	ball_ref = get_parent().get_node("Ball")

	$HitBox.body_entered.connect(func(body):
		var ball = get_parent().get_node("Ball")
		if body == ball:
			ball_touching = true
	)
	$HitBox.body_exited.connect(func(body):
		var ball = get_parent().get_node("Ball")
		if body == ball:
			ball_touching = false
	)

func reset_charge_state() -> void:
	charging = false
	charge_time = 0.0
	slinging = false
	sling_phase = ""
	position.x = original_x
	queue_redraw()

func clamp_y() -> void:
	position.y = clamp(position.y, p_height / 2.0, win_height - p_height / 2.0)

func _physics_process(delta: float) -> void:
	if ball_ref and ball_ref.held and ball_ref.held_by == self:
		if slinging or charging:
			reset_charge_state()

		if Input.is_key_pressed(KEY_D):
			ball_ref.launch_random_from_holder(self)
		elif Input.is_key_pressed(KEY_A):
			if not ball_ref.held_charging:
				ball_ref.start_charge(self)
			ball_ref.update_charge(self, delta)
			var charge_fraction = min(ball_ref.held_charge_time / ball_ref.SERVE_MAX_CHARGE_TIME, 1.0)
			position.x = original_x - sling_direction * WINDUP_DISTANCE * charge_fraction
			queue_redraw()
		elif ball_ref.held_charging:
			var target_x = ball_ref.position.x
			ball_ref.release_charge(self)
			position.x = target_x
			var tween = create_tween()
			tween.tween_property(self, "position:x", original_x, 0.15)

		if Input.is_key_pressed(KEY_W):
			position.y -= get_parent().PADDLE_SPEED * delta
		elif Input.is_key_pressed(KEY_S):
			position.y += get_parent().PADDLE_SPEED * delta
		clamp_y()
		return

	if slinging:
		match sling_phase:
			"out":
				if _step_toward(sling_target_x, sling_speed, delta):
					sling_phase = "pause"
					pause_timer = SLING_PAUSE_TIME
			"pause":
				pause_timer -= delta
				if pause_timer <= 0.0:
					sling_phase = "return"
					var dist = abs(original_x - position.x)
					sling_speed = dist / SLING_RETURN_TIME
			"return":
				if _step_toward(original_x, sling_speed, delta):
					slinging = false
					sling_phase = ""
		clamp_y()
		return

	if Input.is_key_pressed(KEY_W):
		position.y -= get_parent().PADDLE_SPEED * delta
	elif Input.is_key_pressed(KEY_S):
		position.y += get_parent().PADDLE_SPEED * delta
	clamp_y()

	if Input.is_key_pressed(KEY_A):
		if not charging:
			charging = true
			charge_time = 0.0
		charge_time += delta
		var charge_fraction = min(charge_time / MAX_CHARGE_TIME, 1.0)
		if ball_touching:
			position.x = original_x
		else:
			position.x = original_x - sling_direction * WINDUP_DISTANCE * charge_fraction
		queue_redraw()
		if charge_time >= MAX_HOLD_TIME:
			_start_sling()
	elif charging:
		_start_sling()

func _start_sling() -> void:
	current_charge_fraction = min(charge_time / MAX_CHARGE_TIME, 1.0)
	var distance = max_distance * current_charge_fraction
	sling_target_x = original_x + sling_direction * distance
	charging = false
	charge_time = 0.0
	queue_redraw()
	if distance <= 0.0:
		return
	slinging = true
	sling_phase = "out"
	sling_speed = distance / SLING_OUT_TIME

func _step_toward(target_x: float, speed: float, delta: float) -> bool:
	var remaining = target_x - position.x
	if abs(remaining) < 0.5:
		position.x = target_x
		return true
	var dir_sign = sign(remaining)
	var step = min(abs(remaining), speed * delta)
	var collision = move_and_collide(Vector2(dir_sign * step, 0))
	if collision:
		var collider = collision.get_collider()
		if collider == ball_ref and sling_phase == "out":
			ball_ref.apply_sling_hit(self, current_charge_fraction)
	if abs(target_x - position.x) < 0.5:
		position.x = target_x
		return true
	return false

func _draw() -> void:
	if charging and not slinging:
		var charge_fraction = min(charge_time / MAX_CHARGE_TIME, 1.0)
		var line_length = max_distance * charge_fraction
		draw_line(Vector2.ZERO, Vector2(sling_direction * line_length, 0), Color.WHITE, 3.0)
