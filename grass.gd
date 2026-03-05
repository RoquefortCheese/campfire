extends Node3D
@export var grassmesh: Mesh

func create(size: float):
	for i in range(4):
		var meshinstance = MeshInstance3D.new()
		meshinstance.mesh = grassmesh
		meshinstance.rotation.y = randf() * PI * 2
		meshinstance.rotation.x = PI / 2
		meshinstance.position.x = randf_range(-0.5, 0.5)
		meshinstance.position.z = randf_range(-0.5, 0.5)
		meshinstance.scale *= size
		meshinstance.position.y = size / 2
		add_child(meshinstance)
