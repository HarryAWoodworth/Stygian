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

# [ ] Blood Boost
# [ ] Splatter effect when ball queue_frees
# [ ] Better feeling physics

# [ ] Twitcher
# [ ] Simple Stealth system (Directional areas for wheelchair, one smaller for crouching one larger for standing.)

# [ ] Settings

# [ ] Main Menu UI

# [ ] SOUND
#	[ ] Menu Noises
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

# Optimizations
# [ ] Remove rad2deg calls
# [ ] Cull sprites

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
@onready var handGrab := $CanvasLayer/HandGrab
@onready var handEat := $CanvasLayer/HandEat
@onready var fingerTimer := $FingerTimer
@onready var eatingTimer := $EatingTimer
@onready var grabbingTimer := $GrabbingTimer
@onready var bloodball2d := $CanvasLayer/Bloodball
@onready var projectiles := $Projectiles
@onready var veins := $CanvasLayer/Veins
@onready var vignette := $CanvasLayer/Vignette
@onready var green_vignette := $CanvasLayer/GreenVignette
@onready var mouse_pointer := $CanvasLayer/MousePointer
@onready var pause_menu := $CanvasLayer/PauseMenu
@onready var deathbox := $CanvasLayer/DeathBox
@onready var audiostream := $AudioStreamPlayer

const IN_VISION_THRESHOLD_ANGLE := 45
const IN_VISION_THRESHOLD_ANGLE_CORNER_WATCHER := 45

const NUMBER_BUGS_PER_TIMER := 5
const VIGNETTE_TWEEN_TIME := 1.0
const DEATHBOX_TWEEN_TIME := 1.0

const insect = preload("res://scenes/Insect.tscn")
const bloodball = preload("res://scenes/Bloodball.tscn")
# const bloodsplatter = preload("res://scenes/Bloodsplat.tscn")

const rainambience = preload("res://assets/sounds/lightRain.wav")

# Tween for damage vignette
var vignette_tween: Tween
# Tween for health vignette
var green_vignette_tween: Tween
# Tween for death box fade in
var death_tween: Tween

func _debug() -> void:
	pass

func _ready():
	# Randomize
	randomize()
	# Ready deathbox
	deathbox.modulate = Color(1,1,1,0)
	# Ready Menu
	pause_menu.visible = false
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
	# Make mice have a random starting direction
	for mouse in mice.get_children():
		mouse.init(player, Vector3(randf_range(-1.0,1.0), 0, randf_range(-1.0,1.0)))
	# Start rain noise
	audiostream.stream = rainambience
	audiostream.play()

func _physics_process(_delta):
	
	# Handle debug input
	if Input.is_action_just_pressed("debug") :
		_debug()
	
	# Get the angle between player camera and all actors 
	var playerForwardVector: Vector3 = player.camera.get_global_transform().basis.z.normalized()
	for actortype in actors.get_children():
		# Custom angle for corner watchers
		var in_vision_threshold_angle = IN_VISION_THRESHOLD_ANGLE
		if actortype.name == "CornerWatchers": in_vision_threshold_angle = IN_VISION_THRESHOLD_ANGLE_CORNER_WATCHER
		# Loop through all Actor types
		for actor in actortype.get_children():
			# Dont loop through actors with this type
			if actor.has_method("dont_look_at_me"): break
			# Get vector from actor to the player, and get the angle betwee that and the forward player vector
			var vectorToActorFromPlayer = (player.global_transform.origin - actor.global_transform.origin).normalized()
			var angleBetween = rad2deg(playerForwardVector.angle_to(vectorToActorFromPlayer))
			# Set if actor is in player vision by comparing angle
			var isInPlayerVisionAngle = abs(angleBetween) < in_vision_threshold_angle
			# If it is in vision, check if it is visible to the player via raycast
			if isInPlayerVisionAngle:
				var space_state = get_world_3d().direct_space_state
				var isInPlayerVision = _player_shoot_raycast_at(space_state, actor)
				# Set isInPlayerVision equal to raycast result
				if actor.inPlayerVision != isInPlayerVision:
					actor.setInPlayerVision(isInPlayerVision)
			# If not in player vision angle, set to false if not already
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

# Make bugs follow a path across the hud
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

# Hide and show sprites / start animation when player is forming bloodball
func _on_player_form_blood_shot():
	leftHandIdle.visible = false
	rightHandIdle.visible = false
	for vein in veins.get_children():
		vein.visible = false
	leftHandForm.visible = true
	rightHandForm.visible = true
	bloodball2d.show()

# Hide and show sprites, shoot a bloodball if fully formed
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

# Create a bloodball instance and initialize it
func _createBloodball() -> void:
	var bloodballInstance = bloodball.instantiate()
	projectiles.add_child(bloodballInstance)
	# bloodballInstance.add_blood_splat.connect(self._add_blood_splatter)
	bloodballInstance.init(player.shootPoint.global_transform, -1 * player.camera.get_global_transform().basis.z.normalized())

# Hide/Show sprites when player stops giving the finger
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

# Set bloodballCharged, player takes damage
func _on_bloodball_bloodball_charged():
	player.bloodBallCharged = true
	player.bloodloss(player.BLOODBALL_COST)

func _on_player_player_died():
	deathbox.visible = true
	death_tween = create_tween()
	death_tween.tween_property(deathbox, "modulate", Color(1,1,1,1), DEATHBOX_TWEEN_TIME)
	death_tween.tween_callback(_open_retry_menu)

# Hide / Show veins
func _on_player_player_updated_blood(bloodAmount):
	var i = 0
	while i < veins.get_children().size():
		if i <= bloodAmount-1:
			veins.get_child(i).fill()
		else:
			veins.get_child(i).empty()
		i += 1

# Show red vignette on player health loss
func _on_player_player_took_damage():
	if vignette_tween != null:
		vignette_tween.stop()
	# Show red vignette
	vignette.modulate = Color(1,1,1,1)
	# Fade vignette
	vignette_tween = create_tween()
	vignette_tween.tween_property(vignette, "modulate", Color(1,1,1,0), VIGNETTE_TWEEN_TIME)

# Show green vignette on player health gain
func _on_player_player_gained_health():
	if green_vignette_tween != null:
		green_vignette_tween.stop()
	# Show green vignette
	green_vignette.modulate = Color(1,1,1,1)
	# Fade vignette
	green_vignette_tween = create_tween()
	green_vignette_tween.tween_property(green_vignette, "modulate", Color(1,1,1,0), VIGNETTE_TWEEN_TIME)

# Commented out cause decals are kind of funky
func _add_blood_splatter(_collision_point: Vector3, _collision_normal: Vector3) -> void:
	pass
#	var bloodsplatterInstance = bloodsplatter.instantiate()
#	add_child(bloodsplatterInstance)
#	bloodsplatterInstance.global_transform.origin = collision_point
#	bloodsplatterInstance.look_at(collision_normal, Vector3.UP)

# Open the pause menu
func _on_player_open_menu():
	mouse_pointer.setActive(true)
	pause_menu.show_menu(false)

# Close the pause menu
func _on_player_close_menu():
	mouse_pointer.setActive(false)
	pause_menu.hide_menu()

# Free mouse and show retry menu
func _open_retry_menu() -> void:
	# Free the mouse
	player.set_mouse_mode_visible()
	mouse_pointer.setActive(true)
	# Show menu in retry mode
	pause_menu.show_menu(true)

# Called when player grabs a mouse
func _on_player_slurped_mouse():
	print("Here")
	veins.get_child(2).visible = false
	veins.get_child(3).visible = false
	veins.get_child(4).visible = false
	veins.get_child(7).visible = false
	veins.get_child(8).visible = false
	player.playGrabbingSound()
	rightHandIdle.visible = false
	handGrab.visible = true
	grabbingTimer.start()

# Played after a player grabs a mouse, starts eating mouse
func _on_grabbing_timer_timeout():
	grabbingTimer.stop()
	handGrab.visible = false
	handEat.visible = true
	player.playEatingSounds()
	eatingTimer.start()

# Go back to normal after eating mouse
func _on_eating_timer_timeout():
	eatingTimer.stop()
	handEat.visible = false
	rightHandIdle.visible = true
	veins.get_child(2).visible = true
	veins.get_child(3).visible = true
	veins.get_child(4).visible = true
	veins.get_child(7).visible = true
	veins.get_child(8).visible = true
	player.playSwallowSound()
	player.slurpingMouse = false

func _on_pause_menu_resume_game():
	player._close_menu()
