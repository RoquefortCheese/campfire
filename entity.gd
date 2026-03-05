extends CharacterBody3D
class_name Entity

var ray = RayCast3D.new()
var start = true
var cubecolor = Color.YELLOW
var cubescale = 0.4
var cubes = []
var rotations = []
var floor
var floorheight
var alive = true
var bounce = 0

func _ready():
	for i in range(2):
		var cube = MeshInstance3D.new()
		cube.mesh = BoxMesh.new()
		cube.mesh.material = StandardMaterial3D.new()
		cube.mesh.material.albedo_color = cubecolor
		cube.mesh.material.shading_mode = 0
		cube.scale *= cubescale
		add_child(cube)
		cubes.append(cube)
		rotations.append(Vector3(randf() * PI * 2, randf() * PI * 2, randf() * PI * 2))

func _physics_process(delta: float):
	if alive:
		velocity *= 0.5 ** delta
		velocity.y += (floorheight + 1 - position.y) ** 2 * sign(floorheight + 1 - position.y) * delta
		for cubei in range(len(cubes)):
			for axis in range(3):
				cubes[cubei].rotation[axis] += rotations[cubei][axis] * delta
		if abs(Global.player.position.y - position.y) < 6:
			var direction = Global.player.position - position
			direction.y = 0
			velocity += direction.normalized() * 2 * delta
			move_and_slide()
			for i in get_slide_collision_count():
				var collider = get_slide_collision(i).get_collider()
				if collider is Player:
					Global.gamestate = -1
	else:
		if not is_on_floor():
			velocity.y -= 10 * delta
		else:
			velocity.y = 2 * 2 ** -bounce
			bounce += 1
		move_and_slide()

func die():
	alive = false
	velocity *= 0
