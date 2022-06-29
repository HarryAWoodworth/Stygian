extends CharacterBody3D

signal player_seeing_bugs(isSeeingBugs)

var target: Node = null
var health := 5
var inPlayerVision := false
# Eye height is 0 since we only want to activate if the core of the actor is seen
var eye_height_increase := Vector3.ZERO

func setTarget(target_: Node) -> void:
	target = target_

func setInPlayerVision(inPlayerVision_: bool) -> void:
	inPlayerVision = inPlayerVision_
	emit_signal("player_seeing_bugs", inPlayerVision)

func _process(_delta):
	if target != null:
		var target_xz = Vector3(target.global_transform.origin.x, 0 , target.global_transform.origin.z)
		look_at(target_xz, Vector3.UP)
		rotation.x = 0.0

func got_shot() -> void:
	take_damage(1)

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	# Stop bugs when dead
	emit_signal("player_seeing_bugs", false)
	queue_free()
