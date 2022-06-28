extends Node3D

@onready var splashSprite := $Sprite3D
@onready var animPlayer := $AnimationPlayer

func splash() -> void:
	animPlayer.play("splash")
