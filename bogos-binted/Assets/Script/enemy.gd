extends CharacterBody2D

@export var SPEED: float = 120.0
@export var ATTACK_SPEED: float = 40.0
@export var health: int = 3

@export var chase_range: float = 400.0
@export var attack_range: float = 35.0
@export var attack_cooldown: float = 1.0
@export var knockback_strength: float = 300.0

@onready var sprite: AnimatedSprite2D = $Sprite

var player: CharacterBody2D
var can_attack: bool = true
var is_attacking: bool = false
var is_knocked_back: bool = false


func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D

		if not is_instance_valid(player):
			move_and_slide()
			return

	if is_knocked_back:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			SPEED * delta * 10.0
		)

		sprite.play("Hurt")

	elif is_attacking:
		velocity.x = 0.0

	else:
		var dist_x: float = abs(
			player.global_position.x - global_position.x
		)

		var dist_y: float = abs(
			player.global_position.y - global_position.y
		)

		var direction: float = sign(
			player.global_position.x - global_position.x
		)

		if direction != 0.0:
			sprite.flip_h = direction < 0.0

		if dist_x <= chase_range:
			if dist_x <= attack_range and dist_y < 40.0:
				velocity.x = direction * ATTACK_SPEED

				if can_attack and not is_attacking:
					attack()
			else:
				velocity.x = direction * SPEED
				sprite.play("Run")
		else:
			velocity.x = move_toward(
				velocity.x,
				0.0,
				SPEED
			)

			sprite.play("Idle")

	move_and_slide()


func attack() -> void:
	is_attacking = true
	can_attack = false

	velocity.x = 0.0
	sprite.play("Idle")

	await get_tree().create_timer(0.5).timeout

	if is_instance_valid(player) and not is_knocked_back:
		var dist_x: float = abs(
			player.global_position.x - global_position.x
		)

		var dist_y: float = abs(
			player.global_position.y - global_position.y
		)

		if dist_x <= attack_range + 20.0 and dist_y < 40.0:
			sprite.play("Hit")

			if player.has_method("take_damage"):
				player.take_damage()

	await get_tree().create_timer(0.2).timeout

	is_attacking = false

	await get_tree().create_timer(attack_cooldown).timeout

	can_attack = true


func take_damage() -> void:
	health -= 1

	flash_white()
	sprite.play("Hurt")

	if is_instance_valid(player):
		var direction: float = sign(
			global_position.x - player.global_position.x
		)

		if direction == 0.0:
			direction = 1.0

		velocity.x = direction * knockback_strength
		is_knocked_back = true
		reset_knockback()

	if health <= 0:
		die()


func die() -> void:
	var game_manager: Node = get_tree().get_first_node_in_group("game_manager")

	if game_manager != null:
		if game_manager.has_method("enemy_killed"):
			game_manager.enemy_killed()

	queue_free()


func flash_white() -> void:
	modulate = Color(10.0, 10.0, 10.0)

	await get_tree().create_timer(0.1).timeout

	if is_instance_valid(self):
		modulate = Color.WHITE


func reset_knockback() -> void:
	await get_tree().create_timer(0.25).timeout

	if is_instance_valid(self):
		is_knocked_back = false
