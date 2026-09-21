extends CharacterBody2D

@export var SPEED = 500.0
@export var JUMP_VELOCITY = -400.0
@export var gravityMultiplier = 1.2
@export var health = 5
@export var punch_offset_x = 25.0

@onready var animation_player: AnimatedSprite2D = $Sprite
@onready var punch_hitbox: Area2D = $PunchHitbox

var is_punching = false
var is_pounding = false
var is_hurt = false
var punch_count = 1


func _ready() -> void:
	punch_hitbox.monitoring = true


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * gravityMultiplier * delta

		if velocity.y < 0 and not is_pounding and not is_hurt:
			animation_player.play("Jump")
		elif velocity.y > 0 and not is_pounding and not is_hurt:
			animation_player.play("Fall")

	if not is_hurt:
		if Input.is_action_just_pressed("Action") and is_on_floor() and not is_punching:
			is_punching = true
			velocity.x = 0
			animation_player.play("Hit")

			deal_punch_damage()

			await get_tree().create_timer(0.2).timeout
			is_punching = false

		elif Input.is_action_just_pressed("Action") and not is_on_floor() and punch_count > 0:
			is_pounding = true
			velocity.x = 0
			animation_player.play("Pound")

			deal_punch_damage()

			await get_tree().create_timer(0.2).timeout

			is_pounding = false
			punch_count = 0

		if Input.is_action_just_pressed("Jump") and is_on_floor() and not is_punching:
			velocity.y = JUMP_VELOCITY
			punch_count = 1

	var direction := Input.get_axis("Left", "Right")

	if is_punching or is_hurt:
		velocity.x = 0
	else:
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		if direction != 0:
			animation_player.flip_h = direction < 0
			punch_hitbox.position.x = punch_offset_x * (-1.0 if animation_player.flip_h else 1.0)

		if is_on_floor():
			if direction != 0:
				animation_player.play("Run")
			else:
				animation_player.play("Idle")

	move_and_slide()


func deal_punch_damage() -> void:
	var hit_registered = false

	if is_instance_valid(punch_hitbox):
		var overlapping = punch_hitbox.get_overlapping_bodies() + punch_hitbox.get_overlapping_areas()
		for target in overlapping:
			var node = target
			if node == self:
				continue
			if not node.has_method("take_damage") and node.get_parent() and node.get_parent().has_method("take_damage"):
				node = node.get_parent()

			if node != self and node.has_method("take_damage"):
				node.take_damage()
				hit_registered = true

	if not hit_registered:
		var facing_dir = -1.0 if animation_player.flip_h else 1.0
		var nodes = get_tree().get_nodes_in_group("enemies")
		if nodes.is_empty() and get_parent():
			nodes = get_parent().get_children()

		for node in nodes:
			if node != self and node.has_method("take_damage"):
				var x_dist = (node.global_position.x - global_position.x) * facing_dir
				var y_dist = abs(node.global_position.y - global_position.y)
				if x_dist >= -10.0 and x_dist <= 70.0 and y_dist < 50.0:
					node.take_damage()


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
	modulate = Color(10, 10, 10)
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE


func die() -> void:
	get_tree().reload_current_scene()
