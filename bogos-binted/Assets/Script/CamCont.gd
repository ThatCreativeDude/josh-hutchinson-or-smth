extends Camera2D

@onready var character_body_2d: CharacterBody2D = $"../player"
@export var speedX = 5
@export var speedY = 5


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var xx = move_toward(position.x,character_body_2d.position.x,speedX)
	var yy = move_toward(position.y,character_body_2d.position.y,speedY)
	position = Vector2(xx, yy)
	pass
