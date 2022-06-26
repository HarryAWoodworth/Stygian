extends PathFollow2D

# Get random frame and random path
func _ready():
	$Sprite.frame = randi_range(0,2)

func _process(delta):
	offset += randi_range(1000,1500) * delta
	if unit_offset >= 1.0:
		queue_free()
