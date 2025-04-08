extends StaticBody3D
class_name Station

@export var interaction_prompt: String = "Press [F] to use station"
@export var can_interact: bool = true

@onready var camera_point: Node3D = $CameraPoint
@onready var interaction_area: Area3D = null

var input_items = []
var output_items = []	

var camera_original_transform
	
func interact(interactor: Node3D, camera: Camera3D) -> void:	
	if not camera_point:
		print("NEED Camera Point for Station interaction")
	
	camera_original_transform = camera.transform
		
	
