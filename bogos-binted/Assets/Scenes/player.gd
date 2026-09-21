extends CharacterBody2D

@export var SPEED = 500.0
@export var JUMP_VELOCITY = -400.0
@export var gravityMultiplier = 1.2
@export var health = 5
@export var punch_offset_x = 20.0

@onready var animation_player: AnimatedSprite2D = $Sprite
@onready var punch_hitbox: Area2D = $PunchHitbox

var is_punching = false
var is_pounding = false
var is_hurt = false
var punch_count = 1


func _ready() -> void:
	punch_hitbox.monitoring = false
	if not punch_hitbox.body_entered.is_connected(_on_punch_hitbox_body_entered):
		punch_hitbox.body_entered.connect(_on_punch_hitbox_body_entered)


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

			punch_hitbox.monitoring = true
			check_punch_hits()

			await get_tree().create_timer(0.1).timeout

			punch_hitbox.monitoring = false
			await get_tree().create_timer(0.1).timeout

			is_punching = false

		elif Input.is_action_just_pressed("Action") and not is_on_floor() and punch_count > 0:
			is_pounding = true
			velocity.x = 0
			animation_player.play("Pound")

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


func check_punch_hits() -> void:
	for body in punch_hitbox.get_overlapping_bodies():
		_on_punch_hitbox_body_entered(body)


func _on_punch_hitbox_body_entered(body: Node2D) -> void:
	if body != self and body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage()


func take_damage(amount: int = 1) -> void:
	if is_hurt:
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
