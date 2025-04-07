#Character Controller
extends CharacterBody3D

@onready var MainCamera = $MainCamera
@onready var interact_ray  = $MainCamera/InteractionRaycast
@onready var interact_prompt_label = $MainCamera/InteractionPrompt
@onready var push_area = $PushArea
@onready var crosshair = $CanvasLayer/Crosshair

@export var crosshair_radius := 4.0
@export var crosshair_thickness := 2.0
@export var color := Color.BLACK

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const PUSH_FORCE = 1.5
const STEP_HEIGHT = 0.3  # How high objects the character can step over
const MAX_SLOPE_ANGLE = 45.0  # Maximum slope angle the character can walk up

var CameraRotation = Vector2(0,0)
var MouseSensitivity = 0.002
var held_item: Node = null
var current_interactable: Node = null
var current_target: Node = null
var target_type: String = ""
var is_using_station: bool = false
var pickup_tweak_target: Pickable = null
var pickup_tweak_offset: Vector3 = Vector3.ZERO

var show_debug_pickup_offset: bool = false

func _ready():
	initialize()


func _physics_process(delta: float) -> void:
	handle_movement(delta)
	apply_push_to_nearby_bodies()

func _process(delta: float) -> void:
	current_target = interact_ray.get_collider()
	resolve_raycast(current_target)
	if show_debug_pickup_offset:
		debug_pickup_offset()
	
func _input(event):	
	if event is InputEventMouseMotion:
		var MouseEvent = event.relative * MouseSensitivity
		CameraLook(MouseEvent)		
	check_debug_inputs()			
	if event.is_action_pressed("interact"):
		resolve_interaction(current_target)
	elif event.is_action_pressed("drop"):
		if not held_item:
			print("no item being held?")
			return
		if not held_item is Pickable:
			print("Item missing Pickable logic for DROP method")
			return
		held_item.drop()		

func apply_push_to_nearby_bodies():
	for body in push_area.get_overlapping_bodies():
		if body is RigidBody3D and not body.freeze:
			# Check if body has any enabled CollisionShape3D
			var has_enabled_collision := false
			for child in body.get_children():
				if child is CollisionShape3D and not child.disabled:
					has_enabled_collision = true
					break

			if has_enabled_collision:
				var direction = (body.global_transform.origin - global_transform.origin).normalized()
				direction.y = 0  # prevent pushing upward
				body.apply_central_impulse(direction * PUSH_FORCE)

func check_debug_inputs():
	if Input.is_action_pressed("debug_up"):
		pickup_tweak_offset.y += 0.01
	if Input.is_action_pressed("debug_down"):
		pickup_tweak_offset.y -= 0.01
	if Input.is_action_pressed("ui_up"):
		print("action up registered")
		pickup_tweak_offset.z -= 0.01
	if Input.is_action_pressed("ui_down"):
		pickup_tweak_offset.z += 0.01
	if Input.is_action_pressed("ui_left"):
		pickup_tweak_offset.x -= 0.01
	if Input.is_action_pressed("ui_right"):
		pickup_tweak_offset.x += 0.01
	if Input.is_action_pressed("ui_cancel"):
		if Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)	
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func resolve_interaction(target: Node):
	if not target:
		print("No target to interact with")
		return
	if target is Interactable:
		print("Target is Interactable")
		target.interact(self)
	
	elif target is Pickable:
		print("Target is Pickable")
		target.attempt_pickup(self)
		
func CameraLook(Movement: Vector2):
	CameraRotation += Movement
	#clamp rotation to Y axis:
	CameraRotation.y = clamp(CameraRotation.y, -1.5, 1.2)	
	
	transform.basis = Basis()
	MainCamera.transform.basis = Basis()
	
	rotate_object_local(Vector3(0,1,0), -CameraRotation.x) #first rotate y, then rotate main cam instead of kinematic body
	MainCamera.rotate_object_local(Vector3(1,0,0), -CameraRotation.y) #then rotate X ...?	
	
func debug_pickup_offset():
	if held_item and held_item is Pickable:
		pickup_tweak_target = held_item
		var hold_point = get_node("MainCamera/HoldPoint")
		if hold_point:
			held_item.transform.origin = pickup_tweak_offset
	if Input.is_action_just_pressed("ui_accept") and pickup_tweak_target:
		print("Final pickup_offset: ", pickup_tweak_offset)
		
func resolve_raycast(target: Node):
	interact_prompt_label.visible = false
	if target and target.get("interaction_prompt"):
		interact_prompt_label.text = target.interaction_prompt
		interact_prompt_label.visible = true				
	
func handle_movement(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta		
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()
	
func initialize():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	interact_prompt_label.visible = false
