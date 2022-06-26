extends Sprite2D

signal bloodball_charged

@onready var timer := $Timer

const START_SCALE := Vector2.ZERO
const SCALE := Vector2(0.428,0.428)
const TWEEN_TIME := 1.0
const MAX_FRAMES := 14

var tween: Tween

func _ready():
	scale = START_SCALE
	visible = false

func show() -> void:
	timer.start()
	visible = true
	tween = create_tween()
	tween.tween_property(self, "scale", SCALE, TWEEN_TIME)
	tween.tween_callback(_charged)

func hide() -> void:
	visible = false
	scale = START_SCALE
	timer.stop()

func endTween() -> void:
	tween.stop()

func _charged() -> void:
	print("Charged")
	emit_signal("bloodball_charged")

func _on_timer_timeout():
	frame = (frame + 1) % MAX_FRAMES
