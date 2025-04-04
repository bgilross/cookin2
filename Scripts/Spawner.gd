extends InteractableObject

@export var spawn_location: Node3D
@export var item_scene: PackedScene



# Called when the node enters the scene tree for the first time.
func _ready():
	interaction_prompt = " Press [F] to Spawn Ball "
	
func main_interaction(interactor = null):
	_spawnball()
	
func _spawnball():
	print("attempting spawn ball")
	var item_instance = item_scene.instantiate()
	add_child(item_instance)

	if spawn_location == null:
		push_error("spawn_location is null!")
		return

	item_instance.global_transform.origin = spawn_location.global_transform.origin
