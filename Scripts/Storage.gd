extends Area3D
class_name Storage

@export var item_capacity: int = 10
@export var allowed_item: Node = null
@export var can_store: bool = true
@export var interaction_prompt: String = "Press [F] to open storage"

var stored_items: Array[Node] = []
	
func main_interaction(interactor):
	print("[Storage] Interacting with Storage: ", get_parent().name)	
	# Check if the player is holding an item that can be stored
	if interactor.held_item:
		print("[Storage] Player is holding item: ", interactor.held_item.name)
		
		# If we're a base StorageComponent, just handle basic storage
		if self.get_script() == load("res://Scripts/StorageComponent.gd"):
			attempt_add_item(interactor.held_item)
		
		# If we're a derived class (like VisibleStorageObject), let it handle storage
		# This check prevents infinite recursion
	else:
		print("[Storage] No item held for storage")
	
func attempt_add_item(item:Node) -> bool:
	print("[Storage] Attempting to add item: ", item.name)
	if stored_items.size() >= item_capacity:
		print("[Storage] Storage is full")
		return false
		
	if allowed_item:
		if typeof(item) != typeof(allowed_item):
			print("[Storage] Item is not of assigned item type")
			return false
		else:
			print("[Storage] Item is of assigned item type")
			add_item(item)
			return true	
	else:
		add_item(item)
		return true
		
func add_item(item):
	stored_items.append(item)
	print("[Storage] Added item: ", item.name)
