extends Sprite2D

# Get random frame and random path
func _ready():
	frame = randi_range(0,2)

func _process(delta):
	get_parent().offset += randi_range(600,1200) * delta
	if get_parent().unit_offset >= 1.0:
		queue_free()
