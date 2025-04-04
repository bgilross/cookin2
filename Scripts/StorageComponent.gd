extends InteractableObject
class_name StorageComponent

@export var item_capacity: int = 10
@export var allowed_item: Node = null
@export var can_store: bool = true


var items: Array[Node] = []

func _ready():
	interaction_prompt = "Press [F] to open Storage"
	
func attempt_add_item(item:Node) -> bool:
	if items.size() >= item_capacity:
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
	items.append(item)
	print("added item")
	
	
