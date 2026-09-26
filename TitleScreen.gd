extends Control

@onready var play_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/PlayButton
@onready var exit_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/ExitButton
@onready var selector: ColorRect = $SelectorIndicator

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	play_button.focus_entered.connect(func(): _move_selector_to(play_button))
	exit_button.focus_entered.connect(func(): _move_selector_to(exit_button))
	play_button.grab_focus()

	await get_tree().process_frame
	_move_selector_to(play_button)

	var tween = create_tween().set_loops()
	tween.tween_property(selector, "modulate:a", 0.0, 0.4)
	tween.tween_property(selector, "modulate:a", 1.0, 0.4)

func _move_selector_to(button: Button) -> void:
	var target_pos = button.global_position
	selector.global_position = Vector2(target_pos.x - 14, target_pos.y + button.size.y / 2 - selector.size.y / 2)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://GameModeScreen.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
