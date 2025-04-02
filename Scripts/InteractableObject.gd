class_name InteractableObject
extends Node3D

@export var interact_prompt : String 
@export var can_interact : bool = true #ininteraction could be TEMPORARILY disabled, like door is in process of opening

func _interact():
	print("Override This Function!")
	
	
