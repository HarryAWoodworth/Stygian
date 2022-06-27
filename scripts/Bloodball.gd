extends Area3D

@onready var sprite := $Sprite3D
@onready var timer := $Timer

const speed := 10
var velocity := Vector3.ZERO

func init(startForm: Transform3D, direction: Vector3):
	transform = startForm
	velocity = direction * speed

func _process(delta):
	transform.origin += velocity * delta

func _on_timer_timeout():
	sprite.frame = (sprite.frame + 1) % 14

func _on_bloodball_body_entered(body):
	if body.name == "Player": return
	if body.has_method("got_shot"):
		body.got_shot()
	queue_free()

func _on_life_timer_timeout():
	queue_free()
