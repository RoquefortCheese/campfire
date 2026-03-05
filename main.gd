extends Node
@export var world: PackedScene
var current

func _ready():
	Global.gamestate = 0
	var newworld = world.instantiate()
	add_child(newworld)
	current = newworld

func _process(delta: float):
	if Global.gamestate != 0:
		$Label.text = {-1: "You have died.", 1: "You win!"}[Global.gamestate]
		current.process_mode = PROCESS_MODE_DISABLED
		Global.gamestate = 0
		await get_tree().create_timer(2.0).timeout
		remove_child(current)
		var newworld = world.instantiate()
		add_child(newworld)
		current = newworld
		$Label.text = ""
		print("done")
		Global.gamestate = 0
