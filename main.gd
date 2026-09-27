extends Sprite2D

var score := [0,0]# 0:Player, 1: CPU
const PADDLE_SPEED : int = 725
const WINNING_SCORE : int = 7
var game_over := false
var next_server = null
var r_was_pressed := false

func _ready() -> void:
	$hud/WinMessage.visible = false
	$hud/PlayAgain.visible = false
	await start_countdown()

func start_countdown() -> void:
	$hud/Countdown.visible = true
	for text in ["3", "2", "1"]:
		$hud/Countdown.text = text
		await get_tree().create_timer(1.0).timeout
	$hud/Countdown.text = "GO!"
	await get_tree().create_timer(0.7).timeout
	$hud/Countdown.visible = false
	$Ball.new_ball()

func _process(_delta: float) -> void:
	if game_over:
		if Input.is_key_pressed(KEY_R) and not r_was_pressed:
			r_was_pressed = true
			reset_game()
		elif not Input.is_key_pressed(KEY_R):
			r_was_pressed = false

func reset_game() -> void:
	score = [0, 0]
	game_over = false
	$hud/Player1Score.text = "0"
	$hud/Player2Score.text = "0"
	$hud/WinMessage.visible = false
	$hud/PlayAgain.visible = false
	next_server = null
	await start_countdown()

func _on_balltimer_timeout():
	if not game_over:
		$Ball.start_held_serve(next_server)

func _on_score_left_body_entered(body: Node2D) -> void:
	if game_over:
		return
	score[1] += 1
	$hud/Player2Score.text = str(score[1])
	check_for_win()
	if not game_over:
		next_server = $Player1
		$Balltimer.start()

func _on_score_right_body_entered(body: Node2D) -> void:
	if game_over:
		return
	score[0] += 1
	$hud/Player1Score.text = str(score[0])
	check_for_win()
	if not game_over:
		next_server = $Player2
		$Balltimer.start()

func check_for_win():
	if score[0] >= WINNING_SCORE:
		game_over = true
		$hud/WinMessage.text = "Player 1 Wins!"
		$hud/WinMessage.visible = true
		$hud/PlayAgain.text = "Press R to play again"
		$hud/PlayAgain.visible = true
	elif score[1] >= WINNING_SCORE:
		game_over = true
		$hud/WinMessage.text = "Player 2 Wins!"
		$hud/WinMessage.visible = true
		$hud/PlayAgain.text = "Press R to play again"
		$hud/PlayAgain.visible = true
