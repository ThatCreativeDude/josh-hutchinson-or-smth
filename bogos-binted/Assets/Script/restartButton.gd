extends Button
@onready var node_2d: Node2D = $"../../../../.."

func _pressed() -> void:
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_method("restart_game"):
		game_manager.restart_game()
