extends CharacterBody3D

@onready var floorCast := $RayCast3D
@onready var sprite := $Sprite3D

const SPEED := 4.0

var direction := Vector3.ZERO
var inPlayerVision := false
var eye_height_increase := Vector3.ZERO
var player: Node

# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func init(player_: Node, direction_: Vector3) -> void:
	player = player_
	direction = direction_

func _physics_process(delta):
	
	# Apply direction velocity
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	# Move
	# move_and_collide()
	move_and_slide()
	
	# Bounce if mouse hits a wall
	if is_on_wall():
		direction = direction.bounce(get_wall_normal())
		sprite.flip_h = !sprite.flip_h
	# Bounce if mouse hits a ledge
	#if !floorCast.is_colliding():
		#direction = (-direction + Vector3(randf_range(0,0.2), 0, randf_range(0,0.2))).normalized()
		# Move it slightly back so it doesnt get stuck
		#global_transform.origin += direction/5
	
	# Normalize direction
	direction = direction.normalized()
	
	# Turn sprite based on direction compared to player
	if inPlayerVision:
		var playerOriginNoY = player.global_transform.origin
		playerOriginNoY.y = 0
		var mouseOriginNoY = global_transform.origin
		mouseOriginNoY.y = 0
		var vectorFromPlayerToMouse = (mouseOriginNoY - playerOriginNoY).normalized()
		var angleVectorDirection = rad2deg(vectorFromPlayerToMouse.angle_to(direction))
		if angleVectorDirection < 90:
			_face_right()
		else:
			_face_left()

func _face_left() -> void:
	sprite.flip_h = false

func _face_right() -> void:
	sprite.flip_h = true

func setInPlayerVision(inVision: bool) -> void:
	inPlayerVision = inVision

func getSlurped() -> void:
	queue_free()
