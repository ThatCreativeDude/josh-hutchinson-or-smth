extends CharacterBody2D

@export var SPEED: float = 500.0
@export var JUMP_VELOCITY: float = -400.0
@export var gravityMultiplier: float = 1.2
@export var health: int = 5
@export var punch_offset_x: float = 25.0

@onready var animation_player: AnimatedSprite2D = $Sprite
@onready var punch_hitbox: Area2D = $PunchHitbox

var is_punching: bool = false
var is_pounding: bool = false
var is_hurt: bool = false
var punch_count: int = 1


func _ready() -> void:
	add_to_group("player")
	punch_hitbox.monitoring = true


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * gravityMultiplier * delta

		if velocity.y < 0.0 and not is_pounding and not is_hurt:
			animation_player.play("Jump")

		elif velocity.y > 0.0 and not is_pounding and not is_hurt:
			animation_player.play("Fall")

	if not is_hurt:
		if Input.is_action_just_pressed("Action") \
		and is_on_floor() \
		and not is_punching:

			is_punching = true
			velocity.x = 0.0
			animation_player.play("Hit")
			deal_punch_damage()

			await get_tree().create_timer(0.2).timeout

			is_punching = false

		elif Input.is_action_just_pressed("Action") \
		and not is_on_floor() \
		and punch_count > 0:

			is_pounding = true
			velocity.x = 0.0
			animation_player.play("Pound")
			deal_punch_damage()

			await get_tree().create_timer(0.2).timeout

			is_pounding = false
			punch_count = 0

		if Input.is_action_just_pressed("Jump") \
		and is_on_floor() \
		and not is_punching:

			velocity.y = JUMP_VELOCITY
			punch_count = 1

	var direction: float = Input.get_axis("Left", "Right")

	if is_punching or is_hurt:
		velocity.x = 0.0
	else:
		if direction != 0.0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(
				velocity.x,
				0.0,
				SPEED
			)

		if direction != 0.0:
			animation_player.flip_h = direction < 0.0

			var facing_multiplier: float = -1.0 if animation_player.flip_h else 1.0

			punch_hitbox.position.x = punch_offset_x * facing_multiplier

		if is_on_floor():
			if direction != 0.0:
				animation_player.play("Run")
			else:
				animation_player.play("Idle")

	move_and_slide()


func deal_punch_damage() -> void:
	var hit_registered: bool = false

	if is_instance_valid(punch_hitbox):
		var overlapping_bodies: Array[Node2D] = punch_hitbox.get_overlapping_bodies()
		var overlapping_areas: Array[Area2D] = punch_hitbox.get_overlapping_areas()

		for target: Node2D in overlapping_bodies:
			var node: Node = target

			if node == self:
				continue

			if not node.has_method("take_damage"):
				var parent_node: Node = node.get_parent()

				if parent_node != null and parent_node.has_method("take_damage"):
					node = parent_node

			if node != self and node.has_method("take_damage"):
				node.take_damage()
				hit_registered = true

		for target_area: Area2D in overlapping_areas:
			var node: Node = target_area

			if node == self:
				continue

			if not node.has_method("take_damage"):
				var parent_node: Node = node.get_parent()

				if parent_node != null and parent_node.has_method("take_damage"):
					node = parent_node

			if node != self and node.has_method("take_damage"):
				node.take_damage()
				hit_registered = true

	if not hit_registered:
		var facing_dir: float = -1.0 if animation_player.flip_h else 1.0
		var enemy_nodes: Array[Node] = []

		for enemy: Node in get_tree().get_nodes_in_group("enemies"):
			enemy_nodes.append(enemy)

		for enemy_node: Node in enemy_nodes:
			if enemy_node == self:
				continue

			if not enemy_node.has_method("take_damage"):
				continue

			var enemy_body: Node2D = enemy_node as Node2D

			if enemy_body == null:
				continue

			var x_dist: float = (
				enemy_body.global_position.x
				- global_position.x
			) * facing_dir

			var y_dist: float = abs(
				enemy_body.global_position.y
				- global_position.y
			)

			if x_dist >= -10.0 \
			and x_dist <= 70.0 \
			and y_dist < 50.0:

				enemy_node.take_damage()


func take_damage(amount: int = 1) -> void:
	if is_hurt or is_punching or is_pounding:
		return

	health -= amount
	is_hurt = true

	animation_player.play("Hurt")
	flash_white()

	if health <= 0:
		await get_tree().create_timer(0.2).timeout
		die()
	else:
		await get_tree().create_timer(0.4).timeout
		is_hurt = false


func flash_white() -> void:
	modulate = Color(10.0, 10.0, 10.0)

	await get_tree().create_timer(0.1).timeout

	if is_instance_valid(self):
		modulate = Color.WHITE


func die() -> void:
	var game_manager: Node = get_tree().get_first_node_in_group("game_manager")

	if game_manager != null:
		if game_manager.has_method("game_over"):
			game_manager.game_over()
	else:
		get_tree().reload_current_scene()
