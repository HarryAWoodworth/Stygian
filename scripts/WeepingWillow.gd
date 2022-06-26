extends CharacterBody3D

signal player_seeing_bugs(isSeeingBugs)

var target: Node = null
var health := 5
var inPlayerVision := false
var eye_height_increase := Vector3.ZERO

func setInPlayerVision(inPlayerVision_: bool) -> void:
	inPlayerVision = inPlayerVision_
	emit_signal("player_seeing_bugs", inPlayerVision)

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
