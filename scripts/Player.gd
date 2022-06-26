extends CharacterBody3D

var debug := true

signal make_bug

@onready var neck := $Neck
@onready var camera := $Neck/Camera3D
@onready var gunraycast := $Neck/Camera3D/GunRayCast
@onready var standingShape := $StandingCollisionShape
@onready var crouchingShape := $CrouchingCollisionShape
@onready var crouchJumpingShape := $CrouchJumpCollisionShape
@onready var bugtimer := $BugTimer

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY := 0.002
const CROUCH_HEIGHT := 0.25

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

func _ready():
	# Save default standing neck height
	neckHeight = neck.transform.origin.y
	# Set debug camera to active if in debug mode
	if debug:
		$Neck/Camera3D.current = false
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
	# Handle Crouch/Stand
	if Input.is_action_just_pressed("move_crouch"):
		isCrouching = !isCrouching
		# Disable/enable relevant collision shapes and lower camera
		if isCrouching:
			# Lower the neck to crouch height if on floor
			if is_on_floor():
				neck.transform.origin.y = neckHeight * CROUCH_HEIGHT
				crouchingShape.disabled = false
			# Otherwise, crouch jump by only bringing hitbox up
			else:
				crouchJumpingShape.disabled = false
			# Disable standing shape
			standingShape.disabled = true
		# Raise neck back to stand height
		else:
			# If crouch jumped and then landed, raise position before re-enabling standing collision shape
			if !crouchJumpingShape.disabled and is_on_floor():
				transform.origin.y += crouchJumpingShape.transform.origin.y
			neck.transform.origin.y = neckHeight
			standingShape.disabled = false
			crouchingShape.disabled = true
			crouchJumpingShape.disabled = true
			

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
	
	# Shoot gun
	if Input.is_action_just_pressed("weapon_shoot") and !shootingCooldown:
		shootingCooldown = true
		$AnimationPlayer.play("Pistol_Fire")
		gunraycast.force_raycast_update()
		if gunraycast.is_colliding():
			var bodyHit = gunraycast.get_collider()
			if bodyHit.has_method("got_shot"):
				bodyHit.got_shot()

# Let player shoot once anim is done
func _on_animation_player_animation_finished(anim_name):
	if anim_name == "Pistol_Fire":
			shootingCooldown = false

# Start bug timer
func start_bugs() -> void:
	print("Starting bugs")
	lookingAtBugs = true
	bugtimer.start()

# Stop bug timer
func stop_bugs() -> void:
	print("Stopping bugs")
	lookingAtBugs = false
	bugtimer.stop()

# Make a bug fly across the screen
func _on_bug_timer_timeout():
	# Make bug
	emit_signal("make_bug")
	bugtimer.start()
