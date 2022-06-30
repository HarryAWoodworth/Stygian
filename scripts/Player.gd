extends CharacterBody3D

var debug := false

signal make_bug
signal form_blood_shot
signal fire_blood_shot(bloodBallCharged)
signal player_died
signal player_updated_blood(bloodAmount)
signal player_took_damage
signal player_gained_health
signal open_menu
signal close_menu
signal slurped_mouse

@onready var neck := $Neck
@onready var camera := $Neck/Camera3D
@onready var cameraRay := $Neck/Camera3D/CameraRayCast
@onready var standingShape := $StandingCollisionShape
@onready var crouchingShape := $CrouchingCollisionShape
@onready var crouchJumpingShape := $CrouchJumpCollisionShape
@onready var bugtimer := $BugTimer
@onready var shootPoint := $Neck/Position3D
@onready var bugDamageTimer := $BugDamageTimer
@onready var rainCast := $RainCast
@onready var standCast1 := $RayCast3D
@onready var standCast2 := $RayCast3D2
@onready var standCast3 := $RayCast3D3
@onready var standCast4 := $RayCast3D4
@onready var unstuckRay := $Unstuck

const SPEED = 5.0
const JUMP_VELOCITY = 5.0
const CROUCH_HEIGHT := 0.25
# Starting player health, needs to equal vein nodes
const STARTING_BLOOD := 10
# Health cost of firing a bloodball
const BLOODBALL_COST := 1
# Damage per tick of bug hurt
const DAMAGE_FROM_BUGS := 1
# Prevent clipping off small ledges when uncrouching
const TINY_LEDGE_THRESHOLD := 0.4

# Settings
var CROUCH_TOGGLE := false
var MOUSE_SENSITIVITY := 0.002 

# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
# Is the player's weapon in a cooldown state?
var shootingCooldown := false
# Is the player crouching?
var isCrouching := false
# Array of raycasts for stand check
var standCasts: Array
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
# Is the player in the rain?
var inRain := false
# Is the player eating a mouse?
var slurpingMouse := false
# Is the menu open?
var menu_open := false

func _ready():
	# Save stand casts
	standCasts = [standCast1,standCast2,standCast3,standCast4]
	# Starting blood
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
		if menu_open: _close_menu()
	# If escape is pressed, make the mouse visible
	elif event.is_action_pressed("menu_open"):
		if !menu_open: _open_menu()
		else: _close_menu()
	# Move the camera based on the mouse
	if !menu_open and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
			# Clamp camera
			camera.rotation.x = clamp(camera.rotation.x, deg2rad(-60), deg2rad(60))

# Open the menu
func _open_menu() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	emit_signal("open_menu")
	menu_open = true

# Close the menu
func _close_menu() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	emit_signal("close_menu")
	menu_open = false

func _physics_process(delta):
	
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Check for rain
	#inRain = !rainCast.is_colliding()
	
	# Handle Jump
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle Crouch Toggle
	if CROUCH_TOGGLE:
		# Switch stand/crouch based on current state
		if Input.is_action_just_pressed("move_crouch"):
			if !isCrouching: _crouch()
			else: _stand()
	# Handle Crouch Hold
	else:
		# If crouch held, crouch if not already
		if Input.is_action_pressed("move_crouch"):
			if !isCrouching:
				_crouch()
		# Stand if not pressed
		else:
			if isCrouching:
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
	
	# No mouseclick input if eating
	if slurpingMouse: return
	
	# Check for mouse slurp
	if Input.is_action_just_pressed("weapon_shoot") and cameraRay.is_colliding():
		var mouse = cameraRay.get_collider()
		mouse.getSlurped()
		emit_signal("slurped_mouse")
		# Gain a health
		bloodloss(-1)
		slurpingMouse = true
	else:
		# Held down blood shot
		if Input.is_action_pressed("weapon_shoot"):
			if !inRain and !inBloodForm and canForm:
				inBloodForm = true
				emit_signal("form_blood_shot")
			# If released, fire blood shot
		else:
			if !inRain and inBloodForm:
				inBloodForm = false
				emit_signal("fire_blood_shot", bloodBallCharged)
				bloodBallCharged = false

	# Get unstuck
	if unstuckRay.is_colliding():
		print("Unstuck!")
		global_transform.origin.y += neckHeight
	if !isCrouching:
		for ray in standCasts:
			if ray.is_colliding():
				_crouch()
				break

func _crouch() -> void:
	unstuckRay.enabled = false
	# Lower the neck to crouch height if on floor
	if is_on_floor():
		neck.transform.origin.y = neckHeight * CROUCH_HEIGHT
		crouchingShape.disabled = false
	# Otherwise, crouch jump by only bringing hitbox up
	else:
		crouchJumpingShape.disabled = false
	# Disable standing shape
	standingShape.disabled = true
	isCrouching = true

# Stand up, accounting for crouch-jump state
func _stand() -> void:
	if _cantStand(): return
	unstuckRay.enabled = true
	# If crouch jumped and then landed, raise position before re-enabling standing collision shape
	if !crouchJumpingShape.disabled:
		# Use additional height to avoid falling off tiny edges when standing
		transform.origin.y += crouchJumpingShape.transform.origin.y + TINY_LEDGE_THRESHOLD
		crouchJumpingShape.disabled = true
	else:
		neck.transform.origin.y = neckHeight
		crouchingShape.disabled = true
	standingShape.disabled = false
	isCrouching = false

func _cantStand():
	for ray in standCasts:
		if ray.is_colliding(): return true
	return false

# Let player shoot once anim is done
func _on_animation_player_animation_finished(anim_name):
	if anim_name == "Pistol_Fire":
			shootingCooldown = false

# Start bug timer
func start_bugs() -> void:
	lookingAtBugs = true
	bugtimer.start()
	bugDamageTimer.start()

# Stop bug timer
func stop_bugs() -> void:
	lookingAtBugs = false
	bugDamageTimer.stop()
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
	else:
		emit_signal("player_gained_health")
	blood -= amount
	if blood <= 0:
		_die()
	else:
		emit_signal("player_updated_blood", blood)

func _die() -> void:
	emit_signal("player_died")

# Take damage from bugs
func _on_bug_damage_timer_timeout():
	bloodloss(DAMAGE_FROM_BUGS)
