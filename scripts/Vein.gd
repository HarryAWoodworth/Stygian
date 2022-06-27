extends Sprite2D

@onready var timer := $Timer

const SCALE = Vector2(0.035,0.035)
const START_SCALE = Vector2(0.03,0.03)
const TWEEN_TIME = 0.5

# Is the vein emptied?
var isEmpty := false

# Called when the node enters the scene tree for the first time.
func _ready():
	fill()
	scale = START_SCALE
	timer.start()

func empty() -> void:
	isEmpty = true
	modulate = Color(1,1,1)
	timer.stop()

func fill() -> void:
	isEmpty = false
	modulate = Color(1,0,0)

func _on_timer_timeout():
	timer.stop()
	var tween = create_tween()
	tween.tween_property(self, "scale", SCALE, TWEEN_TIME)
	tween.tween_property(self, "scale", START_SCALE, TWEEN_TIME)
	tween.tween_callback(_tween_done)

func _tween_done() -> void:
	if isEmpty: return
	timer.start()
