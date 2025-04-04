#BallInteractable EX of generic pickable item,
# this may be turned into a pickable class that extends interactable that ball would then extend for specifics:

extends InteractableObject
#ovveride the interact function!

func _ready():
	interaction_prompt = "Ball Interact Prompt!"

func _interact ():
	print("Interact With Ball")
	 
