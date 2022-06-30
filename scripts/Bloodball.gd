extends CharacterBody3D

signal add_blood_splat(position, normal)

@onready var sprite := $Sprite3D
@onready var timer := $Timer
@onready var raincast := $RainCast

const speed := 10

func init(startForm: Transform3D, direction: Vector3):
	transform = startForm
	velocity = direction * speed

func _process(_delta):
	# Move ball
	#transform.origin += velocity * delta
	move_and_slide()
	
	# Destroy if in the rain
	raincast.force_raycast_update()
	#if !raincast.is_colliding(): queue_free()
	
	if get_slide_collision_count() > 0:
		var slideCollision = get_slide_collision(0)
		var body = slideCollision.get_collider()
		if body.has_method("got_shot"):
			body.got_shot()
#		else:
#			if body is StaticBody3D:
#				emit_signal("add_blood_splat", slideCollision.get_position(), slideCollision.get_normal())
		queue_free()

func _on_timer_timeout():
	sprite.frame = (sprite.frame + 1) % 14

func _on_life_timer_timeout():
	queue_free()
