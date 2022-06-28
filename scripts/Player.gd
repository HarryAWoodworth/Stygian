extends CharacterBody3D

var debug := false

signal make_bug
signal form_blood_shot
signal fire_blood_shot(bloodBallCharged)
signal player_died
signal player_updated_blood(bloodAmount)
signal player_took_damage

@onready var neck := $Neck
@onready var camera := $Neck/Camera3D
@onready var gunraycast := $Neck/Camera3D/GunRayCast
@onready var standingShape := $StandingCollisionShape
@onready var crouchingShape := $CrouchingCollisionShape
@onready var crouchJumpingShape := $CrouchJumpCollisionShape
@onready var bugtimer := $BugTimer
@onready var shootPoint := $Neck/Position3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const CROUCH_HEIGHT := 0.25
const STARTING_BLOOD := 10
const BLOODBALL_COST := 1

# Settings
var CROUCH_TOGGLE := false
var MOUSE_SENSITIVITY := 0.002 

# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
# Is the player's weapon in a cooldown state?
var shootingCooldown := false
# Is the player crouching?
var isCrouching := false
# The height of the neck
var neckHeight: float
# Is the player looking at weeping willow?
var lookingAtBugs := false
# Is the player in blood form?
var inBloodForm := false
# Is the player's blood ball fully charged?
var bloodBallCharged := false
# Can the player form another blood shot?
var canForm := true
# Eye height
var eye_height_increase: Vector3
# How much blood the player has
var blood: int

func _ready():
	blood = STARTING_BLOOD
	# Save default standing neck height
	neckHeight = neck.transform.origin.y
	eye_height_increase = Vector3(0,neckHeight,0)
	# Set debug camera to active if in debug mode
	if debug:
		camera.current = false
		$DebugCamera.current = true

func _unhandled_input(event) -> void:
	# If screen is clicked, hide mouse
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# If escape is pressed, make the mouse visible
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Move the camera based on the mouse
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
			# Clamp camera
			camera.rotation.x = clamp(camera.rotation.x, deg2rad(-60), deg2rad(60))

func _physics_process(delta):
	
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle Crouch Toggle
	if CROUCH_TOGGLE:
		# Switch stand/crouch based on current state
		if Input.is_action_just_pressed("move_crouch"):
			isCrouching = !isCrouching
			if isCrouching: _crouch()
			else: _stand()
	# Handle Crouch Hold
	else:
		# If crouch held, crouch if not already
		if Input.is_action_pressed("move_crouch"):
			if !isCrouching:
				isCrouching = true
				_crouch()
		# Stand if not pressed
		else:
			_stand()
			

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	
	# Held down blood shot
	if Input.is_action_pressed("weapon_shoot"):
		if !inBloodForm and canForm:
			inBloodForm = true
			emit_signal("form_blood_shot")
	# If released, fire blood shot
	else:
		if inBloodForm:
			inBloodForm = false
			emit_signal("fire_blood_shot", bloodBallCharged)
			bloodBallCharged = false

func _crouch() -> void:
	# Lower the neck to crouch height if on floor
	if is_on_floor():
		neck.transform.origin.y = neckHeight * CROUCH_HEIGHT
		crouchingShape.disabled = false
	# Otherwise, crouch jump by only bringing hitbox up
	else:
		crouchJumpingShape.disabled = false
	# Disable standing shape
	standingShape.disabled = true

# Stand up, accounting for crouch-jump state
func _stand() -> void:
	# If crouch jumped and then landed, raise position before re-enabling standing collision shape
	if !crouchJumpingShape.disabled and is_on_floor():
		transform.origin.y += crouchJumpingShape.transform.origin.y
	neck.transform.origin.y = neckHeight
	standingShape.disabled = false
	crouchingShape.disabled = true
	crouchJumpingShape.disabled = true
	isCrouching = false

# Let player shoot once anim is done
func _on_animation_player_animation_finished(anim_name):
	if anim_name == "Pistol_Fire":
			shootingCooldown = false

# Start bug timer
func start_bugs() -> void:
	lookingAtBugs = true
	bugtimer.start()

# Stop bug timer
func stop_bugs() -> void:
	lookingAtBugs = false
	bugtimer.stop()

# Make a bug fly across the screen
func _on_bug_timer_timeout():
	# Make bug
	emit_signal("make_bug")
	bugtimer.start()

# Take damage to player's blood
func bloodloss(amount: int) -> void:
	# If player took damage, emit signal
	if amount > 0:
		emit_signal("player_took_damage")
	blood -= amount
	if blood <= 0:
		_die()
	else:
		emit_signal("player_updated_blood", blood)

func _die() -> void:
	emit_signal("player_died")
