extends CharacterBody3D

@onready var MainCamera = $MainCamera
@onready var RayCast = $MainCamera/InteractionController

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var CameraRotation = Vector2(0,0)
var MouseSensitivity = 0.002
var held_item: Node = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseMotion:
		var MouseEvent = event.relative * MouseSensitivity
		CameraLook(MouseEvent)
	

func CameraLook(Movement: Vector2):
	CameraRotation += Movement
	#clamp rotation to Y axis:
	CameraRotation.y = clamp(CameraRotation.y, -1.5, 1.2)	
	
	transform.basis = Basis()
	MainCamera.transform.basis = Basis()
	
	rotate_object_local(Vector3(0,1,0), -CameraRotation.x) #first rotate y, then rotate main cam instead of kinematic body
	MainCamera.rotate_object_local(Vector3(1,0,0), -CameraRotation.y) #then rotate X ...?
	
	

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
