extends CharacterBody3D

signal player_seeing_bugs(isSeeingBugs)

var target: Node = null
var health := 5
var inPlayerVision := false

func _physics_process(delta):
	if inPlayerVision:
		$Sprite3D.modulate = Color(1,0,0)
	else:
		$Sprite3D.modulate = Color(1,1,1)

func setInPlayerVision(inPlayerVision_: bool) -> void:
	if inPlayerVision == inPlayerVision_: return
	inPlayerVision = inPlayerVision_
	emit_signal("player_seeing_bugs", inPlayerVision)
		

func got_shot() -> void:
	take_damage(1)

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	queue_free()
