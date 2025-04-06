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
var current_target: Node = null
var target_type: String = ""

var pickup_tweak_target: Pickable = null
var pickup_tweak_offset: Vector3 = Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	interact_prompt_label.visible = false
	
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseMotion:
		var MouseEvent = event.relative * MouseSensitivity
		CameraLook(MouseEvent)
		
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
		
		
		#Char presses F, now we check out the object we are trying to press F on, there are a few scenarios:]
		#object is simple interactable, like a button, it will only have an Interactable script attached, this only has a prompt message and an interact function.
			#in this case we want to press the button, if it's interactable at the moment, if not give message, if so print details
		#object is simple pickable object, like a ball we can hold in our hand or in inventory or on a VSO
			#object will have a script Pickable attached to its Root RigidBody3D., for now we are making ALLL PICKABLES RIGIDBODY 3DS!!!!!
				#could make another separate class for exceptions.
			#we want to call the pickup function
				#obj might handle the following logic:
				#if players hands empty, pickup object into hands
				#if players hands full
					#if held object is VSO and has room
						#pick up object onto VSO
					#if held object NOT VSO or FULL or not compatible VSO or Storage of somekind
						#try to add to player inventory
								#this is interesting because now VSO doesn't actually have a pickup or even use function it just gets used as storage if the conditions are right

func resolve_interaction(target: Node):
	if not target:
		print("No target to interact with")
		return
	#check target type
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
	
	
func _process(delta):
	current_target = interact_ray.get_collider()
	#print("current_target: ", current_target)
	resolve_raycast(current_target)	
	
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
	#if target is Interactable:
		#print("Target Interactable")
	#elif target is Pickable:
		#print("Target Pickable")		
	#if target:
		#for child in target.get_children():
			#if child is Area3D:
				#print("found Area3D child")
				#if child is VisibleStorage:
						#print("found VisibleStorage")						
	
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
