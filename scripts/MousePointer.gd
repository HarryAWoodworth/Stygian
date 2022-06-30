extends Sprite2D

var active: bool

func _ready():
	setActive(false)

func _process(_delta):
	if active:
		position = get_viewport().get_mouse_position()

func setActive(active_: bool) -> void:
	active = active_
	visible = active
