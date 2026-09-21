extends CharacterBody2D

@export var SPEED = 120.0
@export var health = 3

@export var chase_range = 400.0
@export var attack_range = 35.0
@export var attack_cooldown = 1.0
@export var knockback_strength = 300.0

var player: CharacterBody2D
var can_attack = true
var is_attacking = false
var is_knocked_back = false


func _ready() -> void:
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
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 10)
	else:
		var dist_x = abs(player.global_position.x - global_position.x)
		var dist_y = abs(player.global_position.y - global_position.y)
		var direction = sign(player.global_position.x - global_position.x)

		if direction != 0 and has_node("Sprite"):
			$Sprite.flip_h = direction < 0

		if dist_x <= chase_range:
			if dist_x <= attack_range and dist_y < 40.0:
				velocity.x = direction * ATTACK_SPEED
				if can_attack and not is_attacking:
					attack()
			else:
				velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func attack() -> void:
	is_attacking = true
	can_attack = false

	if is_instance_valid(player) and player.has_method("take_damage"):
		var dist_x = abs(player.global_position.x - global_position.x)
		var dist_y = abs(player.global_position.y - global_position.y)
		if dist_x <= attack_range + 10.0 and dist_y < 40.0:
			player.take_damage()

	await get_tree().create_timer(0.2).timeout
	is_attacking = false

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func take_damage() -> void:
	health -= 1
	flash_white()

	if is_instance_valid(player):
		var direction = sign(global_position.x - player.global_position.x)
		if direction == 0:
			direction = 1

		velocity.x = direction * knockback_strength
		is_knocked_back = true
		reset_knockback()

	if health <= 0:
		queue_free()


func flash_white() -> void:
	modulate = Color(10, 10, 10)
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE


func reset_knockback() -> void:
	await get_tree().create_timer(0.2).timeout
	is_knocked_back = false
