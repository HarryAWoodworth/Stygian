extends AudioStreamPlayer3D

func play_sound(sound_stream) -> void:
	stream = sound_stream
	play()

func _on_sound_player_finished():
	queue_free()
