extends Node3D

# Player Health
# Healthbar Veins
# Damage from Corner Watcher touch
# Damage from Weeping Willow bugs

# BLOOD WEAPONS
# Blood Shot
# Blood Boost

@onready var actors := $Actors
@onready var cornerWatchers := $Actors/CornerWatchers
@onready var weepingWillows := $Actors/WeepingWillows
@onready var player := $Player
@onready var paths := $CanvasLayer/Paths
@onready var leftHandIdle := $CanvasLayer/LeftHand
@onready var rightHandIdle := $CanvasLayer/RightHand
@onready var leftHandForm := $CanvasLayer/BloodformLeft
@onready var rightHandForm := $CanvasLayer/BloodformRight
@onready var middleFingerLeft := $CanvasLayer/MiddleFingerLeft
@onready var middleFingerRight := $CanvasLayer/MiddleFingerRight
@onready var fingerTimer := $FingerTimer

const IN_VISION_THRESHOLD_ANGLE := 60

const insect = preload("res://scenes/Insect.tscn")

func _debug() -> void:
	_on_player_make_bug()

func _ready():
	randomize()
	$Bloodball.init(player)
	for cornerWatcher in cornerWatchers.get_children():
		cornerWatcher.setTarget(player)
	for weepingWillow in weepingWillows.get_children():
		weepingWillow.player_seeing_bugs.connect(self._player_is_seeing_bugs)

func _physics_process(delta):
	
	# Handle debug input
	if Input.is_action_just_pressed("debug") :
		_debug()
	
	# Get the angle between player camera and all actors 
	var playerForwardVector: Vector3 = player.camera.get_global_transform().basis.z.normalized()
	playerForwardVector.y = 0
	for actortype in actors.get_children():
		for actor in actortype.get_children():
			var vectorToActorFromPlayer = (player.global_transform.origin - actor.global_transform.origin).normalized()
			vectorToActorFromPlayer.y = 0
			var angleBetween = rad2deg(playerForwardVector.angle_to(vectorToActorFromPlayer))
			# Set if actor is in player vision
			var isInPlayerVisionAngle = abs(angleBetween) < IN_VISION_THRESHOLD_ANGLE
			# If so, check if it is visible via raycast
			if isInPlayerVisionAngle:
				var space_state = get_world_3d().direct_space_state
				var isInPlayerVision = _player_shoot_raycast_at(space_state, actor)
				# Set equal to raycast
				if actor.inPlayerVision != isInPlayerVision:
					actor.setInPlayerVision(isInPlayerVision)
			# If not in player vision, set to false if not already
			else:
				if actor.inPlayerVision:
					actor.setInPlayerVision(false)

func _player_shoot_raycast_at(space_state, actor: Node) -> bool:
	var rayParams := PhysicsRayQueryParameters3D.new()
	rayParams.from = player.neck.global_transform.origin
	var actorSightPoint = actor.global_transform.origin + actor.eye_height_increase
	rayParams.to = actorSightPoint
	var result = space_state.intersect_ray(rayParams)
	return result.collider == actor
	#player.sightcast.cast_to(actor.global_transform.origin)
	#return player.sightcast.get_collider == actor

# Make a random bug follow a random path across the hud
func _on_player_make_bug():
	var insectInstance = insect.instantiate()
	var randomPath = _randomPath()
	randomPath.add_child(insectInstance)

# Start/Stop the player seeing bugs
func _player_is_seeing_bugs(isSeeingBugs: bool) -> void:
	if isSeeingBugs:
		player.start_bugs()
	else:
		player.stop_bugs()

# Return random path from Paths
func _randomPath() -> Path2D:
	var pathList = paths.get_children()
	return pathList[randi_range(0,pathList.size()-1)]

func _on_player_form_blood_shot():
	leftHandIdle.visible = false
	rightHandIdle.visible = false
	leftHandForm.visible = true
	rightHandForm.visible = true

func _on_player_fire_blood_shot():
	player.canForm = false
	leftHandForm.visible = false
	rightHandForm.visible = false
	middleFingerLeft.visible = true
	middleFingerRight.visible = true
	fingerTimer.start()

func _on_finger_timer_timeout():
	fingerTimer.stop()
	middleFingerLeft.visible = false
	middleFingerRight.visible = false
	leftHandIdle.visible = true
	rightHandIdle.visible = true
	player.canForm = true
