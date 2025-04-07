extends StaticBody3D
class_name Station

@export var interaction_prompt: String = "Press [F] to use station"
@export var can_interact: bool = true

@onready var interaction_area: Area3D = null

var input_items = []
var output_items = []

func interact(interactor: Node3D) -> void:
	#begin using/open menu for Station
	print("Override this method")
	
