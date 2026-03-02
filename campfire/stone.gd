extends StaticBody3D

func create(start: Vector3, end: Vector3):
	for axis in range(3):
		position[axis] = (start[axis] + end[axis]) / 2
		scale[axis] = (end[axis] - start[axis])
