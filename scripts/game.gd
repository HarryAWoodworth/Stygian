extends Node3D

@onready var actors := $Actors
@onready var cornerWatchers := $Actors/CornerWatchers
@onready var weepingWillows := $Actors/WeepingWillows
@onready var player := $Player
@onready var insects := $CanvasLayer/Insects
@onready var paths := $CanvasLayer/Paths

const IN_VISION_THRESHOLD := 60

const insect = preload("res://scenes/Insect.tscn")

func _debug() -> void:
	_on_player_make_bug()

func _ready():
	randomize()
	for cornerWatcher in cornerWatchers.get_children():
		cornerWatcher.setTarget(player)
	for weepingWillow in weepingWillows.get_children():
		weepingWillow.player_seeing_bugs.connect(self._start_player_bugs)

func _physics_process(delta):
	
	# Move insects
	if player.lookingAtBugs:
		for path in paths.get_children():
			path.get_children()[0].offset += randi_range(600,1200) * delta
	
	# Handle debug input
	if Input.is_action_just_pressed("debug") :
		_debug()
	
	# Get the angle between player camera and actor 
	var playerForwardVector: Vector3 = player.camera.get_global_transform().basis.z.normalized()
	playerForwardVector.y = 0
	for actortype in actors.get_children():
		for actor in actortype.get_children():
			var vectorToActorFromPlayer = (player.global_transform.origin - actor.global_transform.origin).normalized()
			vectorToActorFromPlayer.y = 0
			var angleBetween = rad2deg(playerForwardVector.angle_to(vectorToActorFromPlayer))
			# Check if actor is in player vision
			actor.setInPlayerVision(abs(angleBetween) < IN_VISION_THRESHOLD)

# Make a random bug follow a random path across the hud
func _on_player_make_bug():
	var insectInstance = insect.instantiate()
	var randomPath = _randomPath()
	randomPath.get_children()[0].add_child(insectInstance)

# Start/Stop the player seeing bugs
func _start_player_bugs(shouldStart: bool) -> void:
	if shouldStart:
		player.start_bugs()
	else:
		player.stop_bugs()

# Return random path from Paths
func _randomPath() -> Path2D:
	var pathList = paths.get_children()
	return pathList[randi_range(0,pathList.size()-1)]
	
