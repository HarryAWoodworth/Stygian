extends CharacterBody3D

@onready var timer := $DamageTimer

const SPEED := 2
const DAMAGE := 1

var target: Node = null
var killingTarget: Node = null
var health := 5
var inPlayerVision := false
var eye_height_increase := Vector3(0,0.5,0)

func setTarget(newTarget: Node) -> void:
	if newTarget != null:
		target = newTarget
		set_physics_process(true)
	else:
		print("CORNERWATCHER: Tried to set target as null.")

func _physics_process(delta):
	if target == null:
		set_physics_process(false)
		return
	# Position of target
	var targetPosition: Vector3 = target.global_transform.origin
	# Normalize the vector because only direction is needed
	var directionToTarget: Vector3 = (targetPosition - global_transform.origin).normalized() 
	
	var space_state = get_world_3d().direct_space_state
	if !inPlayerVision and _canSeePlayer(space_state):
		# Move and slide towards target position
		velocity = directionToTarget * SPEED
		move_and_slide()

func _canSeePlayer(space_state) -> bool:
	var rayParams := PhysicsRayQueryParameters3D.new()
	var sightPoint = global_transform.origin + eye_height_increase
	rayParams.from = sightPoint
	var result
	
	# Eyes
	rayParams.to = target.global_transform.origin + target.eye_height_increase
	result = space_state.intersect_ray(rayParams)
	if "collider" in result:
		if result.collider == target: return true
	
	# Torso
	rayParams.to = target.global_transform.origin
	result = space_state.intersect_ray(rayParams)
	if "collider" in result:
		if result.collider == target: return true
	
	# Feet
	rayParams.to = target.global_transform.origin - target.eye_height_increase
	result = space_state.intersect_ray(rayParams)
	# Return result at end, will be false if can't see
	if "collider" in result:
		return result.collider == target
	else:
		return false

func setInPlayerVision(inPlayerVision_: bool) -> void:
	if inPlayerVision == inPlayerVision_: return
	inPlayerVision = inPlayerVision_

func got_shot() -> void:
	take_damage(1)

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	queue_free()

func _on_damage_area_body_entered(body):
	if body.name == "Player":
		killingTarget = body
		body.bloodloss(DAMAGE)
		timer.start()

func _on_damage_area_body_exited(body):
	killingTarget = null
	timer.stop()

func _on_damage_timer_timeout():
	if killingTarget != null:
		killingTarget.bloodloss(DAMAGE)
	timer.start()
