extends GPUParticles3D

# TY Miziziziz
# https://www.youtube.com/watch?v=KFDDiN2MD6g

@export var splash_area := 50.0
@export var splashes_per_second := 300
@export var splash_pool_size := 200
@export var length_to_ground := 400
@export var how_far_splash_into_ground := 0.1

var rainSplash = preload("res://scenes/RainSplash.tscn")
var splashes := []

var time_since_last_splash := 0.0
var splash_rate := 1.0 / splashes_per_second
var cur_splash_index := 0

# Create a pool of RainSplash instances
func _ready():
	for i in range(splash_pool_size):
		var splashInstance = rainSplash.instantiate()
		add_child(splashInstance)
		splashes.append(splashInstance)
		splashInstance.splashSprite.visible = false

func _process(delta):
	time_since_last_splash += delta
	# Make a splash based on time since last splash and the splash rate
	# Use while so we can have more than 1 splash per frame
	while time_since_last_splash >= splash_rate:
		_make_splash(get_world_3d().direct_space_state)
		# Incremement which splash from the pool we're using
		cur_splash_index += 1
		cur_splash_index %= splashes.size()
		# Decrement time
		time_since_last_splash -= splash_rate
	
func _make_splash(space_state) -> void:
	var xpos = randf_range(-splash_area,splash_area)
	var zpos = randf_range(-splash_area,splash_area)
	var startpos = global_transform.origin + Vector3(xpos, 0, zpos)

	# Intersect Ray to find ground
	var rayParams := PhysicsRayQueryParameters3D.new()
	rayParams.from = startpos
	rayParams.to = startpos - Vector3(0, length_to_ground, 0)
	var result = space_state.intersect_ray(rayParams)
	# If ground is found, get the current splash from the pool and set its positiona and play splash anim
	if result.size() > 0:
		print("Splish Splash")
		var current_splash = splashes[cur_splash_index]
		current_splash.global_transform.origin = result.position + Vector3(0,how_far_splash_into_ground,0)
		current_splash.splash()
