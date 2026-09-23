extends Node

@onready var enemies_label: Label = $Camera2D/CanvasGroup/HUD/enemies_label
@onready var win_ui: Control = $Camera2D/CanvasGroup/win_ui
@onready var lose_ui: Control = $Camera2D/CanvasGroup/Lose_ui

var enemies_left: int = 0
var game_ended: bool = false


func _ready() -> void:
	add_to_group("game_manager")

	win_ui.hide()
	lose_ui.hide()

	await get_tree().process_frame

	enemies_left = get_tree().get_nodes_in_group("enemies").size()
	update_enemies_label()

	if enemies_left <= 0:
		win_game()


func enemy_killed() -> void:
	if game_ended:
		return

	enemies_left -= 1
	update_enemies_label()

	if enemies_left <= 0:
		win_game()


func update_enemies_label() -> void:
	if enemies_label != null:
		enemies_label.text = "Enemies Left: " + str(enemies_left)


func win_game() -> void:
	if game_ended:
		return

	game_ended = true
	win_ui.show()
	get_tree().paused = true


func game_over() -> void:
	if game_ended:
		return

	game_ended = true
	lose_ui.show()
	get_tree().paused = true


func restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
