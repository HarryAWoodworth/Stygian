extends Node3D

# Questions for Alpha:
# Is the sound design consistent?
# Is the sound design scary?
# Is the atmosphere scary?
# How does the player movement physics feel
# Did the player feel too wide or skinny?
# Does the game run well (Does it lag at any points?)
# Does the game have clear mechanics?
# Did you have fun playing the game?

# [X] Fix ray and camera misalignment
# [x] Add mouse slurp and green vignette
# [X] Add larger mouse hitbox
# [X] Make player camera raycast shorter (and then longer)
# [X] Remove white edge around Weeping Willow insect sprites and fixed pixel blur

# [ ] Fix regained veins not pumping blood
# [ ] Make it so mouse flips sprite based on what direction it is travelling from you

# [ ] Blood Boost
# [ ] Splatter effect when ball queue_frees
# [ ] Better feeling physics

# [ ] Twitcher
# [ ] Simple Stealth system (Directional areas for wheelchair, one smaller for crouching one larger for standing.)

# [ ] Pause Menu + Settings

# [ ] Death Screen / Menu

# [ ] Menu UI
# [ ] Settings
# [ ] Start

# [ ] SOUND
#	[ ] Ambience
#	[ ] Music
#	[ ] Rat Slurp
#	[ ] Damage Taken
#	[ ] Damage Given
#	[ ] Blood ball 
#	[ ] Blood Form
#	[ ] Blood ball flying
#	[ ] Heartbeat when low health
#	[ ] Corner Watcher
#		[ ] Ambient
#		[ ] Approaching Noise
#		[ ] Hit Noise
#		[ ] Attack Noise
#		[ ] Death Noise
#	[ ] Weeping Willow
#		[ ] Ambient
#		[ ] Bug Noise
#		[ ] Hit Noise
#		[ ] Death Noise
#	[ ] Wheelchair Twitcher
#		[ ] Ambient
#		[ ] Wheel Noise
#		[ ] Angry Noises
#		[ ] Attack Noises
#		[ ] Hit Noise
#		[ ] Death Noise

# Things you turn on with blood?
# Ex. A generator for lights/doors that runs on blood

@onready var actors := $Actors
@onready var cornerWatchers := $Actors/CornerWatchers
@onready var weepingWillows := $Actors/WeepingWillows
@onready var mice := $Actors/Mice
@onready var player := $Player
@onready var paths := $CanvasLayer/Paths
@onready var leftHandIdle := $CanvasLayer/LeftHand
@onready var rightHandIdle := $CanvasLayer/RightHand
@onready var leftHandForm := $CanvasLayer/BloodformLeft
@onready var rightHandForm := $CanvasLayer/BloodformRight
@onready var middleFingerLeft := $CanvasLayer/MiddleFingerLeft
@onready var middleFingerRight := $CanvasLayer/MiddleFingerRight
@onready var fingerTimer := $FingerTimer
@onready var bloodball2d := $CanvasLayer/Bloodball
@onready var projectiles := $Projectiles
@onready var veins := $CanvasLayer/Veins
@onready var vignette := $CanvasLayer/Vignette
@onready var green_vignette := $CanvasLayer/GreenVignette
@onready var vignette_timer := $VignetteTimer
@onready var green_vignette_timer := $GreenVignetteTimer

const IN_VISION_THRESHOLD_ANGLE := 45
const IN_VISION_THRESHOLD_ANGLE_CORNER_WATCHER := 45

const NUMBER_BUGS_PER_TIMER := 5
const VIGNETTE_TWEEN_TIME := 1.0

const insect = preload("res://scenes/Insect.tscn")
const bloodball = preload("res://scenes/Bloodball.tscn")
# const bloodsplatter = preload("res://scenes/Bloodsplat.tscn")

# Tween for damage vignette
var vignette_tween: Tween
# Tween for health vignette
var green_vignette_tween: Tween

func _debug() -> void:
	pass

func _ready():
	# Randomize
	randomize()
	# Ready Vignettes
	vignette.modulate = Color(1,1,1,0)
	green_vignette.modulate = Color(1,1,1,0)
	# Set player as Corner Watcher target
	for cornerWatcher in cornerWatchers.get_children():
		cornerWatcher.setTarget(player)
	# Connect Weeping Willow signals and set target
	for weepingWillow in weepingWillows.get_children():
		weepingWillow.player_seeing_bugs.connect(self._player_is_seeing_bugs)
		weepingWillow.setTarget(player)
	# Make mice have a random direction to go
	for mouse in mice.get_children():
		mouse.init(Vector3(randf_range(-1.0,1.0), 0, randf_range(-1.0,1.0)))

func _physics_process(_delta):
	
	# Handle debug input
	if Input.is_action_just_pressed("debug") :
		_debug()
	
	# Get the angle between player camera and all actors 
	var playerForwardVector: Vector3 = player.camera.get_global_transform().basis.z.normalized()
	for actortype in actors.get_children():
		var in_vision_threshold_angle = IN_VISION_THRESHOLD_ANGLE
		if actortype.name == "CornerWatchers": in_vision_threshold_angle = IN_VISION_THRESHOLD_ANGLE_CORNER_WATCHER
		for actor in actortype.get_children():
			if actor.has_method("dont_look_at_me"): break
			var vectorToActorFromPlayer = (player.global_transform.origin - actor.global_transform.origin).normalized()
			var angleBetween = rad2deg(playerForwardVector.angle_to(vectorToActorFromPlayer))
			# Set if actor is in player vision
			var isInPlayerVisionAngle = abs(angleBetween) < in_vision_threshold_angle
			# If so, check if it is visible to the player via raycast
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

# Shoot raycast to eyes, torso, and feet
func _player_shoot_raycast_at(space_state, actor: Node) -> bool:
	var rayParams := PhysicsRayQueryParameters3D.new()
	rayParams.from = player.neck.global_transform.origin
	var result
	# Eyes
	rayParams.to = actor.global_transform.origin + actor.eye_height_increase
	result = space_state.intersect_ray(rayParams)
	if "collider" in result:
		if result.collider == actor: return true
	# Torso
	rayParams.to = actor.global_transform.origin
	result = space_state.intersect_ray(rayParams)
	if "collider" in result:
		if result.collider == actor: return true
	# Feet
	rayParams.to = actor.global_transform.origin - actor.eye_height_increase
	result = space_state.intersect_ray(rayParams)
	# Return since it will be false if actor is unseen
	if "collider" in result:
		return result.collider == actor
	else:
		return false

# Make 4 random bugs follow a random path across the hud
func _on_player_make_bug():
	for n in NUMBER_BUGS_PER_TIMER:
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
	for vein in veins.get_children():
		vein.visible = false
	leftHandForm.visible = true
	rightHandForm.visible = true
	bloodball2d.show()

func _on_player_fire_blood_shot(bloodBallCharged: bool):
	player.canForm = false
	bloodball2d.hide()
	leftHandForm.visible = false
	rightHandForm.visible = false
	if bloodBallCharged:
		middleFingerLeft.visible = true
		middleFingerRight.visible = true
		fingerTimer.start()
		_createBloodball()
	else:
		_on_finger_timer_timeout()

func _createBloodball() -> void:
	var bloodballInstance = bloodball.instantiate()
	projectiles.add_child(bloodballInstance)
	# bloodballInstance.add_blood_splat.connect(self._add_blood_splatter)
	bloodballInstance.init(player.shootPoint.global_transform, -1 * player.camera.get_global_transform().basis.z.normalized())

func _on_finger_timer_timeout():
	fingerTimer.stop()
	bloodball2d.endTween()
	middleFingerLeft.visible = false
	middleFingerRight.visible = false
	leftHandIdle.visible = true
	rightHandIdle.visible = true
	for vein in veins.get_children():
		vein.visible = true
	player.canForm = true

func _on_bloodball_bloodball_charged():
	player.bloodBallCharged = true
	player.bloodloss(player.BLOODBALL_COST)

func _on_player_player_died():
	print("YOU DIED")

# Hide / Show veins
func _on_player_player_updated_blood(bloodAmount):
	var i = 0
	while i < veins.get_children().size():
		if i <= bloodAmount-1:
			veins.get_child(i).fill()
		else:
			veins.get_child(i).empty()
		i += 1

func _on_player_player_took_damage():
	if vignette_tween != null:
		vignette_tween.stop()
	vignette.modulate = Color(1,1,1,1)
	vignette_timer.start()

func _on_player_player_gained_health():
	if green_vignette_tween != null:
		green_vignette_tween.stop()
	print("Slurp")
	green_vignette.modulate = Color(1,1,1,1)
	green_vignette_timer.start()

func _on_vignette_timer_timeout():
	vignette_timer.stop()
	vignette_tween = create_tween()
	vignette_tween.tween_property(vignette, "modulate", Color(1,1,1,0), VIGNETTE_TWEEN_TIME)

func _on_green_vignette_timer_timeout():
	green_vignette_timer.stop()
	green_vignette_tween = create_tween()
	green_vignette_tween.tween_property(green_vignette, "modulate", Color(1,1,1,0), VIGNETTE_TWEEN_TIME)

func _add_blood_splatter(collision_point: Vector3, collision_normal: Vector3) -> void:
	pass
#	var bloodsplatterInstance = bloodsplatter.instantiate()
#	add_child(bloodsplatterInstance)
#	bloodsplatterInstance.global_transform.origin = collision_point
#	bloodsplatterInstance.look_at(collision_normal, Vector3.UP)
