#Character Controller

extends CharacterBody3D

@onready var MainCamera = $MainCamera
@onready var interact_ray  = $MainCamera/InteractionRaycast
@onready var interact_prompt_label = $MainCamera/InteractionPrompt
@onready var push_area = $PushArea

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const PUSH_FORCE = 10.0

var CameraRotation = Vector2(0,0)
var MouseSensitivity = 0.002
var held_item: Node = null
var current_interactable: Node = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	interact_prompt_label.visible = false
	
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseMotion:
		var MouseEvent = event.relative * MouseSensitivity
		CameraLook(MouseEvent)
		
	if event.is_action_pressed("interact"):
		if current_interactable:
			print ("Char: interacting with ", current_interactable.name)
			current_interactable.main_interaction(self)
		else:
			print ("No interactable to interact with found")
	elif event.is_action_pressed("drop"):
		if not held_item:
			print("no item being held?")
			return
		var object = find_interactable_in(held_item)
		if not object:
			print("missing object logic for ", held_item.name)
			return
		object.drop()
	

func CameraLook(Movement: Vector2):
	CameraRotation += Movement
	#clamp rotation to Y axis:
	CameraRotation.y = clamp(CameraRotation.y, -1.5, 1.2)	
	
	transform.basis = Basis()
	MainCamera.transform.basis = Basis()
	
	rotate_object_local(Vector3(0,1,0), -CameraRotation.x) #first rotate y, then rotate main cam instead of kinematic body
	MainCamera.rotate_object_local(Vector3(1,0,0), -CameraRotation.y) #then rotate X ...?
	
	
func _process(delta):
	raycast_interactables()
		

func raycast_interactables():
	var collider = interact_ray.get_collider()
	interact_prompt_label.text = ''
	current_interactable = null

	if collider:
		# The collider is the RigidBody3D (Ball) not the collisionShape3D.... yea
		var interactable = find_interactable_in(collider)
		if interactable:
			#maybe should check for interactble here, but I think I want prompt to show up either way....?
			print("looking at ", interactable)
			
			interact_prompt_label.text = interactable.interaction_prompt
			interact_prompt_label.visible = true
			current_interactable = interactable
					
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


func find_interactable_in(node: Node) -> InteractableObject:
	for child in node.get_children():
		if child is InteractableObject:
			return child
	return null
