#Interactble basic class for Buttons and simple Interactables. no storage,no pickable,

class_name Interactable
extends StaticBody3D

@export var interaction_prompt : String = "Press [F] to Interact"
@export var can_interact : bool = true #ininteraction could be TEMPORARILY disabled, like door is in process of opening

func interact(interactor):
	print("Override This Function!")


	
