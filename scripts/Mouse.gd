extends CharacterBody3D

@onready var floorCast := $RayCast3D
@onready var sprite := $Sprite3D
@onready var audiostream := $AudioStreamPlayer3D
@onready var squeaktimer := $SqueakTimer
@onready var area := $Area3D/CollisionShape3D

const SPEED := 3.0
const MIN_SQUEAK_TIME := 4
const MAX_SQUEAK_TIME := 8

var squeak1 = preload("res://assets/sounds/MouseSqueak1.mp3")
var squeak2 = preload("res://assets/sounds/MouseSqueak2.mp3")
var squeak3 = preload("res://assets/sounds/MouseSqueak3.mp3")
var squeak4 = preload("res://assets/sounds/MouseSqueak4.mp3")
var squeak5 = preload("res://assets/sounds/MouseSqueak5.mp3")
var squeak6 = preload("res://assets/sounds/MouseSqueak6.mp3")
var squeak7 = preload("res://assets/sounds/MouseSqueak7.mp3")
var squeak8 = preload("res://assets/sounds/MouseSqueak8.mp3")

var shriek1 = preload("res://assets/sounds/MouseDeath1.mp3")
#var shriek2 = preload("res://assets/sounds/MouseDeath2.mp3")
var shriek3 = preload("res://assets/sounds/MouseDeath3.mp3")
var shriek4 = preload("res://assets/sounds/MouseDeath4.mp3")

var squeaks = [squeak1,squeak2,squeak3,squeak4,squeak5,squeak6,squeak7,squeak8]
var shrieks = [shriek1,shriek3,shriek4]

var direction := Vector3.ZERO
var inPlayerVision := false
var eye_height_increase := Vector3.ZERO
var player: Node
var dead := false

# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func init(player_: Node, direction_: Vector3) -> void:
	player = player_
	direction = direction_
	squeaktimer.start(MIN_SQUEAK_TIME)

func _physics_process(delta):
	
	# Apply direction velocity
	direction = direction.normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	# Move
	# move_and_collide()
	move_and_slide()
	
	# Bounce if mouse hits a wall
	if is_on_wall():
		direction = direction.bounce(get_wall_normal())
	# Bounce if mouse hits a ledge
	#if !floorCast.is_colliding():
		#direction = (-direction + Vector3(randf_range(0,0.2), 0, randf_range(0,0.2))).normalized()
		# Move it slightly back so it doesnt get stuck
		#global_transform.origin += direction/5
	
	# Turn sprite based on direction compared to player
	if inPlayerVision:
		var playerOriginNoY = player.global_transform.origin
		playerOriginNoY.y = 0
		var mouseOriginNoY = global_transform.origin
		mouseOriginNoY.y = 0
		var angleVectorDirection = rad2deg(playerOriginNoY.signed_angle_to(direction, Vector3.UP))
		if angleVectorDirection < 0: _face_left()
		else: _face_right()
		

func _face_left() -> void:
	sprite.flip_h = false

func _face_right() -> void:
	sprite.flip_h = true

func setInPlayerVision(inVision: bool) -> void:
	inPlayerVision = inVision

func getSlurped() -> void:
	dead = true
	area.disabled = true
	sprite.visible = false
	set_physics_process(false)
	audiostream.stop()
	var index = randi() % shrieks.size()
	print(index)
	audiostream.stream = shrieks[index]
	audiostream.play()

# Make random squeak noise
func _squeak() -> void:
	if dead: return
	audiostream.stream = squeaks[randi() % squeaks.size()]
	audiostream.play()

func _on_squeak_timer_timeout():
	_squeak()
	squeaktimer.start((randi() % MAX_SQUEAK_TIME)+ MIN_SQUEAK_TIME)

func _on_audio_stream_player_3d_finished():
	if !dead: return
	queue_free()
