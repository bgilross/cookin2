extends Control

@export var radius := 4.0
@export var color := Color.BLACK

func _ready():
	set_anchors_and_offsets_preset(PRESET_CENTER)
	set_size(Vector2(radius * 2 + 2, radius * 2 + 2))
	queue_redraw()

func _draw():
	var center := size / 2
	draw_circle(center, radius, color)
