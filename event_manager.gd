extends Node

var ball_ref = null
const EVENT_INTERVAL := 5.0
const EVENT_DURATION := 5.0

enum Event { GIANT_BALL }
var current_event = -1

func _ready() -> void:
	print("Event manager ready")
	ball_ref = get_parent().get_node("Ball")
	var timer = Timer.new()
	timer.wait_time = EVENT_INTERVAL
	timer.autostart = true
	timer.timeout.connect(_on_interval_timeout)
	add_child(timer)

func _on_interval_timeout() -> void:
	if current_event != -1:
		return
	trigger_random_event()

func trigger_random_event() -> void:
	var event = Event.GIANT_BALL
	current_event = event
	match event:
		Event.GIANT_BALL:
			start_giant_ball()

func start_giant_ball() -> void:
	print("Giant ball triggered")
	ball_ref.scale = Vector2(3, 3)
	var timer = get_tree().create_timer(EVENT_DURATION)
	await timer.timeout
	end_giant_ball()

func end_giant_ball() -> void:
	ball_ref.scale = Vector2(1, 1)
	current_event = -1
