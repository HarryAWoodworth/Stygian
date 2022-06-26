extends Sprite3D

func _on_timer_timeout():
	frame = (frame + 1) % 14
