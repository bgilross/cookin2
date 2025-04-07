extends Pickable
class_name Food

enum FoodState {
	WHOLE,
	CUT,
	PREPPED,
	COOKED,
}

var current_state = FoodState.WHOLE
var quality = 100 #0-bad 100-good
var processing_history = []

var dirt_spots = []
var is_clean = false

func _ready() -> void:
	add_dirt_to_sphere()

func change_state(new_state):
	current_state = new_state
	
func reduce_quality(amount, reason):
	quality -= amount
	processing_history.append(reason)
	print(name, "quality redcued to ", quality, "because : ", reason)

func get_quality():
	return quality

func get_state():
	return current_state
	
func add_dirt_to_sphere(max_dirt_spots: int = 0):
	var dirt = Sprite3D.new()
	dirt.texture = preload("res://ImgAssets/vecteezy_pile-of-soil-scattered_48112031.png")
	for i in max_dirt_spots:
		dirt.pixel_size = 0.05
		
		var theta = randf() * 2 * PI
		var phi = acos(2 * randf() - 1)
		var radius = self.radius
		
		var x = radius * sin(phi) * cos(theta)
		var y = radius * sin(phi) * sin(theta)
		var z = radius * cos(phi)
		
		dirt.position = Vector3(x, y, z)
		add_child(dirt)
		dirt_spots.append(dirt)
		
		
