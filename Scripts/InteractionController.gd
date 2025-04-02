extends RayCast3D

@onready var interact_prompt_label : Label = get_node("InteractionPrompt")

func _process(delta):
	#every frame: GET whatever object we're looking at... basically
	var object = get_collider() #get_collider is built in from RayCast3D which we extend from, it gets collider from whatever it's hitting, it CAN be NULL
	interact_prompt_label.text = ""
	
	if object and object is InteractableObject:
		#We don't want to interact with a static mesh or something that can't interact.
		#also make sure object Can interact is set to true:
		if object.can_interact == false:
			return
			
		interact_prompt_label.text = " [E] " + object.interact_prompt
		
		if Input.is_action_just_pressed("interact"):
			object._interact()
