extends Control

@onready var vs_ai_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/VsAIButton
@onready var vs_player_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/VsPlayerButton
@onready var selector: ColorRect = $SelectorIndicator

func _ready() -> void:
	vs_ai_button.pressed.connect(_on_vs_ai_pressed)
	vs_player_button.pressed.connect(_on_vs_player_pressed)
	vs_ai_button.focus_entered.connect(func(): _move_selector_to(vs_ai_button))
	vs_player_button.focus_entered.connect(func(): _move_selector_to(vs_player_button))
	vs_ai_button.grab_focus()

	await get_tree().process_frame
	_move_selector_to(vs_ai_button)

	var tween = create_tween().set_loops()
	tween.tween_property(selector, "modulate:a", 0.0, 0.4)
	tween.tween_property(selector, "modulate:a", 1.0, 0.4)

func _move_selector_to(button: Button) -> void:
	var target_pos = button.global_position
	selector.global_position = Vector2(target_pos.x - 14, target_pos.y + button.size.y / 2 - selector.size.y / 2)

func _on_vs_ai_pressed() -> void:
	get_tree().change_scene_to_file("res://pong_vs_human.tscn")

func _on_vs_player_pressed() -> void:
	get_tree().change_scene_to_file("res://pong_vs_human.tscn")
