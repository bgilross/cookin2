extends InteractableObject

@export var spawn_location: Node3D
@export var item_scene: PackedScene



# Called when the node enters the scene tree for the first time.
func _ready():
	interaction_prompt = " Press [F] to Spawn Ball "
	
func main_interaction():
	_spawnball()
	
func _spawnball():
	var item_instance = item_scene.instantiate()
	item_instance.global_position = spawn_location
	add_child(item_instance)
