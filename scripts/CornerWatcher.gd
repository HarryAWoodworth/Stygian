extends CharacterBody3D

const SPEED := 1

var target: Node = null

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
	# Move and slide towards target position
	velocity = directionToTarget * SPEED
	move_and_slide()
