extends VBoxContainer

signal resume_game

@onready var resume := $ResumeButton
@onready var settings := $SettingsButton
@onready var restart := $RestartButton

const HOVER_MODULATE := Color(0.5,0.5,0.5)

func show_menu(retryMode: bool) -> void:
	restart.visible = retryMode
	resume.visible = !retryMode
	visible = true

func hide_menu() -> void:
	visible = false

# When resume is pressed, close the menu
func _on_resume_button_pressed(): emit_signal("resume_game")

# When settings is pressed, open settings menu
func _on_settings_button_pressed():
	pass

# When restart button is pressed, restart level
func _on_restart_button_pressed():
	pass

# Hover signals
func _on_resume_button_mouse_entered(): resume.modulate = HOVER_MODULATE
func _on_resume_button_mouse_exited(): resume.modulate = Color(1,1,1)
func _on_settings_button_mouse_entered(): settings.modulate = HOVER_MODULATE
func _on_settings_button_mouse_exited(): settings.modulate = Color(1,1,1)
func _on_restart_button_mouse_entered(): restart.modulate = HOVER_MODULATE
func _on_restart_button_mouse_exited(): restart.modulate = Color(1,1,1)
