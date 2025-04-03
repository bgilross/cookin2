#BallInteractable EX of generic pickable item,
# this may be turned into a pickable class that extends interactable that ball would then extend for specifics:

extends InteractableObject
#ovveride the interact function!

func _interact ():
	interact_prompt = "Ball interact prompt"
	print("Interact With Ball")
	 
