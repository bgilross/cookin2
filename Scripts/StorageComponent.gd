extends InteractableObject
class_name StorageComponent

@export var item_capacity: int = 10
@export var allowed_item: Node = null
@export var can_store: bool = true


var stored_items: Array[Node] = []

func _ready():
	interaction_prompt = "Press [F] to open Storage"
	
func main_interaction(interactor):
	print("interacting with Storage Crate: ")
	#probably for regular crates this would be opening them up to view contents in a UI
	#for VSO Visible Storage Object, they will have a class extending this, probably with a function to check and set parameters before running attempt add./add
	
	
func attempt_add_item(item:Node) -> bool:
	if stored_items.size() >= item_capacity:
		print("Storage is full")
		return false
		
	if allowed_item:
		if typeof(item) != typeof(allowed_item):
			print("Item is not of assigned item type")
			return false
		else:
			print("Item is of assigned item type")
			add_item(item)
			return true	
	elif not allowed_item:
		add_item(item)
		return true
	else:
		return false
		
func add_item(item):
	stored_items.append(item)
	print("added item")
	
	
