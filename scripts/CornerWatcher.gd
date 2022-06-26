extends CharacterBody3D

const SPEED := 2

var target: Node = null
var health := 5
var inPlayerVision := false

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
	
	if !inPlayerVision:
		# Move and slide towards target position
		velocity = directionToTarget * SPEED
		move_and_slide()

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
