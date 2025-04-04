#InteractableObject this class is the base for ALL objects which can be interacted with in ANY way, I hope.
#extending from here would be Storage Objects, Pickable Objects, Buttons, etc.

class_name InteractableObject
extends Node

@export var interaction_prompt : String = "Press [F] to Interact"
@export var can_interact : bool = true #ininteraction could be TEMPORARILY disabled, like door is in process of opening


func _main_interaction():
	print("Override This Function!")


	
