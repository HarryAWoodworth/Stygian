extends CharacterBody3D

@onready var floorCast := $RayCast3D

const SPEED := 5.0

var direction := Vector3.ZERO

# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func init(direction_: Vector3) -> void:
	direction = direction_

func _physics_process(delta):
	
	# Apply direction velocity
	direction = direction.normalized()
	velocity.x = direction.x * SPEED
	velocity.x = direction.z * SPEED
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	# Move
	move_and_slide()
	# Move Raycast
	floorCast.global_transform.origin = global_transform.origin + (velocity.normalized() * 0.1)
	
	# Bounce if mouse hits a wall
	if is_on_wall():
		var slideCollision = get_last_slide_collision()
		direction = slideCollision.get_normal()
	# Bounce if mouse hits a ledge
	if !floorCast.is_colliding():
		pass
		#direction = (-direction + Vector3(randf_range(0,0.2), 0, randf_range(0,0.2))).normalized()
		# Move it slightly back so it doesnt get stuck
		#global_transform.origin += direction/5

# Player doesnt need to calculate angle to this actor
func dont_look_at_me() -> void:
	pass
