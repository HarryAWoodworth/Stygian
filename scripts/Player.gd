extends CharacterBody3D

@onready var neck := $Neck
@onready var camera := $Neck/Camera3D
@onready var gunraycast := $GunRayCast

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY := 0.002

# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
# Is the player's weapon in a cooldown state?
var shootingCooldown := false

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
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

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
			#if bodyHit.has_method("got_shot"):
			print("You shot a ", bodyHit.name)


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "Pistol_Fire":
			print("Done")
			shootingCooldown = false
