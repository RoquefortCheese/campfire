extends Node3D
@export var stonescene: PackedScene
@export var treescene: PackedScene
@export var entityscene: PackedScene
@export var grassmesh: Mesh
@export var vinemesh: Mesh
@export var mossmesh: Mesh
@export var glowmesh: Mesh
@export var finaltreescene: PackedScene
const worldsize = 128
const interfloorgap = 2
const floorheight = 10
const totalheight = interfloorgap + floorheight
const numfloors = 8
const roomsperfloor = 4
const mindim = 8
const maxdim = 24
var entitiesperfloor = 8
var lastfloor
var map = {}
var exits = {}
var grasstransforms = []
var vinetransforms = []
var floorstuff = {}
var loaded = {}
var minimaps = {}

func _ready():
	Global.player = $Player
	$Player.position = Vector3(worldsize / 2, 0, worldsize / 2)
	$MinimapSprite.scale *= 256 / worldsize
	worldgen()

func newstone(start: Vector3, end: Vector3, floor: int):
	var stone = stonescene.instantiate()
	stone.create(start, end)
	floorstuff[floor].append(stone)

func tube(center: Vector3, dimensions: Vector3, floor: int):
	for i in range(4):
		var axis = i / 2 * 2
		var stone = stonescene.instantiate()
		stone.position = center
		stone.position[axis] += (dimensions[axis] + 0.5) * ((i % 2) * 2 - 1)
		stone.scale[2 - axis] = dimensions[axis] * 2 + 2
		stone.scale[1] = dimensions[1] * 2
		floorstuff[floor].append(stone)

func blankmap(fill: bool):
	var newmap = {}
	for x in range(worldsize):
		for y in range(worldsize):
			newmap[Vector2(x, y)] = fill
	return newmap

func quadtreestone(floormap: Dictionary, lowbound: Vector2, squaresize: int, minheight: int, maxheight: int, floor: int):
	var fillstate = floormap[lowbound]
	for x in range(lowbound.x, lowbound.x + squaresize):
		for z in range(lowbound.y, lowbound.y + squaresize):
			if floormap[Vector2(x, z)] != fillstate:
				for xx in [lowbound.x, lowbound.x + squaresize / 2]:
					for yy in [lowbound.y, lowbound.y + squaresize / 2]:
						quadtreestone(floormap, Vector2(xx, yy), squaresize / 2, minheight, maxheight, floor)
				return
	if fillstate:
		newstone(Vector3(lowbound.x, minheight, lowbound.y), Vector3(lowbound.x + squaresize, maxheight, lowbound.y + squaresize), floor)

func quadtreecarpet(floormap: Dictionary, lowbound: Vector2, squaresize: int, mesh: Mesh, elevation: int, floor: int):
	var fillstate = floormap[lowbound]
	for x in range(lowbound.x, lowbound.x + squaresize):
		for z in range(lowbound.y, lowbound.y + squaresize):
			if floormap[Vector2(x, z)] != fillstate:
				for xx in [lowbound.x, lowbound.x + squaresize / 2]:
					for yy in [lowbound.y, lowbound.y + squaresize / 2]:
						quadtreecarpet(floormap, Vector2(xx, yy), squaresize / 2, mesh, elevation, floor)
				return
	if fillstate:
		var carpet = MeshInstance3D.new()
		carpet.mesh = mesh
		carpet.position = Vector3(lowbound.x + squaresize / 2., elevation + 0.001, lowbound.y + squaresize / 2.)
		carpet.scale *= squaresize
		floorstuff[floor].append(carpet)

func randomrect(lowerbound: Vector2, upperbound: Vector2):
	var randomtile1 = Vector2(randi_range(lowerbound.x, upperbound.x), randi_range(lowerbound.y, upperbound.y))
	var randomtile2 = Vector2(randi_range(lowerbound.x, upperbound.x), randi_range(lowerbound.y, upperbound.y))
	return {"start": Vector2(min(randomtile1.x, randomtile2.x), min(randomtile1.y, randomtile2.y)), "end": Vector2(max(randomtile1.x, randomtile2.x), max(randomtile1.y, randomtile2.y))}

func tileinrect(tile: Vector2, lowerbound: Vector2, upperbound: Vector2):
	return lowerbound.x <= tile.x and upperbound.x >= tile.x and lowerbound.y <= tile.y and upperbound.y >= tile.y

func loadfloor(floor: int):
	for stone in floorstuff[floor]:
		add_child(stone)
	loaded[floor] = true
	spawnentities(floor)

func unloadfloor(floor: int):
	for stone in floorstuff[floor]:
		remove_child(stone)
	loaded[floor] = false

func spawnentities(floor: int):
	var occupiedtiles = []
	for i in range(entitiesperfloor):
		while true:
			var randomtile = Vector2(randi_range(0, worldsize - 1), randi_range(0, worldsize - 1))
			if not map[floor][randomtile] and randomtile not in occupiedtiles:
				var entity = entityscene.instantiate()
				entity.position = Vector3(randomtile.x, totalheight * -(floor + 1) + 1.25, randomtile.y)
				entity.floor = floor
				entity.floorheight = entity.position.y - 1.25
				add_child(entity)
				floorstuff[floor].append(entity)
				occupiedtiles.append(randomtile)
				break

func worldgen():
	#print("starting worldgen...")
	var metatotalheight = totalheight * numfloors
	for floor in range(numfloors):
		#print("floor " + str(floor) + "...")
		#print("checkpoint 1")
		floorstuff[floor] = []
		minimaps[floor] = Image.create(worldsize, worldsize, false, Image.FORMAT_RGB8)
		var topheight = -floor * totalheight
		tube(Vector3(worldsize / 2, -(floor + 0.5) * totalheight, worldsize / 2), Vector3(worldsize / 2, totalheight / 2, worldsize / 2), floor)
		var exit
		while true:
			exit = Vector2(randi_range(0, worldsize - 1), randi_range(0, worldsize - 1))
			if floor == 0 or not map[floor - 1][exit]:
				break
		exits[floor] = exit
		#print("checkpoint 2")
		var exitmap = blankmap(true)
		exitmap[exit] = false
		if floor == 0:
			while true:
				var treepos = exit + Vector2(0.5, 0.5) + (Vector2.RIGHT * randf_range(4, 6)).rotated(randf() * 2 * PI)
				if min(treepos.x, treepos.y) > 2 and max(treepos.x, treepos.y) < worldsize - 2:
					var oaktree = treescene.instantiate()
					oaktree.position = Vector3(treepos.x, 0, treepos.y)
					oaktree.scale *= randf_range(2, 3)
					oaktree.rotation.y = randf() * PI * 2
					add_child(oaktree)
					break
		quadtreestone(exitmap, Vector2(0, 0), worldsize, topheight - interfloorgap, topheight, floor)
		#print("checkpoint 3")
		#print("checkpoint 4")
		var floormap = blankmap(true)
		var hallends = []
		var nomorerooms = false
		for roomi in range(roomsperfloor):
			var attempts = 0
			var start; var end
			while true:
				var rect = randomrect(Vector2(0, 0), Vector2(worldsize - 1, worldsize - 1))
				start = rect["start"]
				end = rect["end"]
				var dims = Vector2(end.x - start.x, end.y - start.y)
				var validroom = true
				if min(dims.x, dims.y) < mindim or max(dims.x, dims.y) > maxdim:
					validroom = false
				if validroom and roomi == 0 and not tileinrect(exit, start, end):
					validroom = false
				if validroom:
					for x in range(start.x, end.x + 1):
						for y in range(start.y, end.y + 1):
							if not floormap[Vector2(x, y)]:
								validroom = false
				if validroom:
					break
				attempts += 1
				if attempts == 2 ** 12 and roomi != 0:
					nomorerooms = true
					break
			if nomorerooms:
				#print("no more rooms")
				break
			#print("checkpoint 5")
			for x in range(start.x, end.x + 1):
				for y in range(start.y, end.y + 1):
					floormap[Vector2(x, y)] = false
			var pillars
			var hallend
			while true:
				#print("start")
				pillars = []
				for pillari in range(3):
					pillars.append(randomrect(start, end))
				var minipillarmap = {}
				for x in range(start.x, end.x + 1):
					for y in range(start.y, end.y + 1):
						minipillarmap[Vector2(x, y)] = "empty"
				for pillar in pillars:
					for x in range(pillar["start"].x, pillar["end"].x + 1):
						for y in range(pillar["start"].y, pillar["end"].y + 1):
							minipillarmap[Vector2(x, y)] = "pillar"
				var validpillars = true
				if validpillars:
					var totalpillar = 0
					for tile in minipillarmap:
						if minipillarmap[tile] == "pillar":
							totalpillar += 1
					if totalpillar / len(minipillarmap) > 0.5:
						validpillars = false
				#print("passed 1")
				if validpillars:
					while true:
						hallend = Vector2(randi_range(start.x, end.x), randi_range(start.y, end.y))
						if minipillarmap[hallend] == "empty":
							break
				if validpillars:
					var cornercovered = false
					for corner in [start, end, Vector2(start.x, end.y), Vector2(end.x, start.y)]:
						if minipillarmap[corner] == "pillar":
							cornercovered = true
					if not cornercovered:
						validpillars = false
				#print("passed 2")
				if validpillars:
					if exit in minipillarmap and minipillarmap[exit] == "pillar":
						validpillars = false
				#print("passed 3")
				if validpillars:
					for tile in minipillarmap:
						if minipillarmap[tile] == "empty":
							var emptyneighbors = 0
							for disp in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
								var neighbor = tile + disp
								if neighbor in minipillarmap and minipillarmap[neighbor] == "empty":
									emptyneighbors += 1
							if emptyneighbors <= 1:
								validpillars = false
				#print("passed 4")
				if validpillars:
					minipillarmap[hallend] = "flood"
					while true: #inefficient floodfilling
						var done = true
						for tile in minipillarmap:
							if minipillarmap[tile] == "flood":
								for disp in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
									var neighbor = tile + disp
									if neighbor in minipillarmap and minipillarmap[neighbor] == "empty":
										done = false
										minipillarmap[neighbor] = "flood"
						if done:
							break
					if "empty" in minipillarmap.values():
						validpillars = false
				#print("passed 5")
				if validpillars:
					break
			for pillar in pillars:
				for x in range(pillar["start"].x, pillar["end"].x + 1):
					for y in range(pillar["start"].y, pillar["end"].y + 1):
						floormap[Vector2(x, y)] = true
			hallends.append(hallend)
			#print("checkpoint 6")
		#print("checkpoint 7")
		for halli in range(1, len(hallends)):
			var mindist = worldsize * 16
			var bestconnections = []
			for halli2 in range(halli):
				var dist = abs(hallends[halli].x - hallends[halli2].x) + abs(hallends[halli].y - hallends[halli2].y)
				if dist < mindist:
					mindist = dist
					bestconnections.clear()
				if dist == mindist:
					bestconnections.append(halli2)
			var connecting = bestconnections.pick_random()
			var end = hallends[connecting]
			var walker = hallends[halli]
			var direction = randi_range(0, 1)
			var canturn = true
			while walker != end:
				if end[direction] == walker[direction]:
					direction = 1 - direction
					canturn = false
				if canturn and randf() < 0.2:
					direction = 1 - direction
				walker[direction] += sign(end[direction] - walker[direction])
				floormap[walker] = false
				##print(walker)
		#print("checkpoint 8")
		map[floor] = floormap
		if floor == numfloors - 1:
			while true:
				var finaltreepos = Vector2(randi_range(0, worldsize - 1), randi_range(0, worldsize - 1))
				if not floormap[finaltreepos]:
					var tree = finaltreescene.instantiate()
					tree.position = Vector3(finaltreepos.x, -metatotalheight, finaltreepos.y)
					add_child(tree)
					break
		quadtreestone(floormap, Vector2(0, 0), worldsize, topheight - interfloorgap - floorheight, topheight - interfloorgap, floor)
		loaded[floor] = false
		
		#for x in range(worldsize):
			#for y in range(worldsize):
				#if not floormap[Vector2(x, y)]:
					#minimaps[floor].set_pixel(x, y, Color.GREEN)
	for floor in range(numfloors):
		var topheight = floor * -totalheight
		for texture in [mossmesh, glowmesh]:
			var relfloor = {mossmesh: floor, glowmesh: numfloors - 1 - floor}[texture]
			if relfloor < 4:
				var barren = null
				if floor != numfloors - 1:
					barren = exits[floor + {mossmesh: 0, glowmesh: 1}[texture]]
				var relground = topheight + {mossmesh: 0, glowmesh: -totalheight}[texture]
				var noise = FastNoiseLite.new()
				noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
				noise.frequency = 0.015
				noise.offset = Vector3.ONE * randf() * 10000
				var carpetmap = blankmap(false)
				for x in range(worldsize):
					for y in range(worldsize):
						var noisevalue = clampf(noise.get_noise_2d(x, y), -1, 1) / 2 + 0.5
						var relative = noisevalue - (1 - 2 ** -(relfloor / 2.))
						if relative > 0:
							carpetmap[Vector2(x, y)] = true
							var strength = relative / 2 ** -(relfloor * 0.85)
							if Vector2(x, y) != barren and strength > 0.25:
								var size = strength * 2 / 2 ** (relfloor * 0.85)
								for i in range(8):
									var origin = Vector3(x + randf(), size / 2 + relground, y + randf())
									var bass = Basis(Vector3.UP, randf() * PI * 2) * size
									##print(bass, origin)
									{mossmesh: grasstransforms, glowmesh: vinetransforms}[texture].append(Transform3D(bass, origin))
				carpetmap[barren] = false
				quadtreecarpet(carpetmap, Vector2(0, 0), worldsize, texture, relground, floor)
	#for floori in range(numfloors - 1):
		#minimaps[floori].set_pixel(exits[floori + 1].x, exits[floori + 1].y, Color.BLUE)
		
	quadtreestone(blankmap(true), Vector2(0, 0), worldsize, -metatotalheight - 1, -metatotalheight, numfloors - 1)
	#print("checkpoint 9")
	$GrassMultiMesh.multimesh.instance_count = len(grasstransforms)
	for i in range(len(grasstransforms)):
		$GrassMultiMesh.multimesh.set_instance_transform(i, grasstransforms[i])
	$VineMultiMesh.multimesh.instance_count = len(vinetransforms)
	for i in range(len(vinetransforms)):
		$VineMultiMesh.multimesh.set_instance_transform(i, vinetransforms[i])
	Global.map = map
	#print("checkpoint 10")

func _process(delta: float):
	var playerfloor = int(-ceil(($Player.position.y + $Player.get_node("CameraPivot").position.y) / (floorheight + interfloorgap)))
	if playerfloor != lastfloor:
		if playerfloor == 4:
			$GrassMultiMesh.hide()
			$VineMultiMesh.show()
		if playerfloor != -1:
			$MinimapSprite.texture = ImageTexture.create_from_image(minimaps[playerfloor])
		for floori in range(numfloors):
			if abs(floori - playerfloor - 1) <= 1:
				if not loaded[floori]:
					loadfloor(floori)
			else:
				if loaded[floori]:
					unloadfloor(floori)
		var lightfraction = (1 - float(playerfloor + 1) / numfloors)
		#print(lightfraction)
		$WorldEnvironment.environment.ambient_light_energy = 0.5 * lightfraction
		$DirectionalLight1.light_energy = 0.25 * lightfraction
		$DirectionalLight2.light_energy = 0.25 * lightfraction
		lastfloor = playerfloor
	if playerfloor != -1:
		var playertile = Vector2(floor($Player.position.x), floor($Player.position.z))
		var changingtiles = []
		var minimap = minimaps[playerfloor]
		for x in range(max(0, playertile.x - 1), min(worldsize, playertile.x + 2)):
			for y in range(max(0, playertile.y - 1), min(worldsize, playertile.y + 2)):
				if minimaps[playerfloor].get_pixel(x, y).r == 0:
					changingtiles.append(Vector2(x, y))
		for tile in changingtiles:
			var shade = randi_range(64, 191) if map[playerfloor][tile] else 255
			minimap.set_pixel(tile.x, tile.y, Color.from_rgba8(shade, shade, shade))
		minimap.set_pixel(playertile.x, playertile.y, Color.BLUE)
		$MinimapSprite.texture.set_image(minimaps[playerfloor])
	if Input.is_action_just_pressed("toggle minimap"):
		$MinimapSprite.visible = not $MinimapSprite.visible
