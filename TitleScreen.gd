extends Control

@onready var play_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/PlayButton
@onready var exit_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/ExitButton
@onready var selector: ColorRect = $SelectorIndicator
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var title_label: Label = $CenterContainer/VBoxContainer/Label

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	play_button.focus_entered.connect(func(): _move_selector_to(play_button))
	exit_button.focus_entered.connect(func(): _move_selector_to(exit_button))
	play_button.grab_focus()

	await get_tree().process_frame
	_move_selector_to(play_button)

	var label_target_pos = title_label.position
	title_label.position.y -= 250

	var hold_time = 1.0
	var reveal_time = 3.5

	var fade_tween = create_tween()
	fade_tween.tween_interval(hold_time)
	fade_tween.tween_property(fade_overlay, "modulate:a", 0.0, reveal_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	var label_tween = create_tween()
	label_tween.tween_interval(hold_time)
	label_tween.tween_property(title_label, "position:y", label_target_pos.y, reveal_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

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
