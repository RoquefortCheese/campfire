extends CharacterBody3D

var camera
const cameraspeed = 1./200
const speed = 5
const jumpvel = 6

func _ready():
	camera =  $CameraPivot.get_node("Camera3D")

func _physics_process(delta: float):
	var direction = Vector2.ZERO
	if Input.is_action_pressed("forward"):
		direction += Vector2.UP
	if Input.is_action_pressed("back"):
		direction += Vector2.DOWN
	if Input.is_action_pressed("left"):
		direction += Vector2.LEFT
	if Input.is_action_pressed("right"):
		direction += Vector2.RIGHT
	direction = (direction.normalized() * speed).rotated(-$CameraPivot.rotation.y)
	velocity.x = direction.x
	velocity.z = direction.y
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jumpvel
	if not is_on_floor():
		velocity.y -= 10 * delta
	move_and_slide()

func _process(delta: float):
	if Input.is_action_just_pressed("mouseclick"):
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			var hit = camera.get_node("RayCast3D").get_collider()
			if hit is Entity:
				hit.die()
	if Input.is_action_just_pressed("escape"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			$CameraPivot.rotate_y(event.relative.x * -cameraspeed)
			camera.rotation.x = clamp(camera.rotation.x + event.relative.y * -cameraspeed, -PI * 0.49, PI * 0.49)
