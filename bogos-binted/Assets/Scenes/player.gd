extends CharacterBody2D


@export var SPEED = 500
@export var JUMP_VELOCITY = -400.0
@export var gravityMultiplier = 1.2
@export var visuals: Node2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var punch_number = 1
var is_punching = false

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * gravityMultiplier * delta
		

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_just_pressed("Action"):
		is_punching = true
		if punch_number == 1:
			animation_player.play("Punch")
			punch_number = 2
		else:
			animation_player.play("Punch_2")
			punch_number = 1
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("Left","Right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	if not is_punching:
		if (direction == 1 or direction == -1):
			visuals.scale.x = direction
			animation_player.play("Walk")
		else:
			animation_player.play("Idle")
	move_and_slide()
