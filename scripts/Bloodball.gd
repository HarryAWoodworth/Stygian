extends Sprite3D

const ROTATION_SPEED := 5.0

var player: Node = null

func init(player_: Node) -> void:
	player = player_

func _process(delta):
	if player: look_at(player.neck.global_transform.origin)
	rotate_z(delta * ROTATION_SPEED)
