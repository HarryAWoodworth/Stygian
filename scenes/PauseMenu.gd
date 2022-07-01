extends VBoxContainer

signal resume_game

@onready var resume := $ResumeButton
@onready var settings := $SettingsButton
@onready var restart := $RestartButton
@onready var menu := $MenuButton
@onready var quit := $QuitButton

const HOVER_MODULATE := Color(0.5,0.5,0.5)

func show_menu(retryMode: bool) -> void:
	print("Show menu")
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

# Go back to the main menu
func _on_menu_button_pressed():
	pass

# Quit the game
func _on_quit_button_pressed(): get_tree().quit()

# Hover signals
func _on_resume_button_mouse_entered(): resume.modulate = HOVER_MODULATE
func _on_resume_button_mouse_exited(): resume.modulate = Color(1,1,1)
func _on_settings_button_mouse_entered(): settings.modulate = HOVER_MODULATE
func _on_settings_button_mouse_exited(): settings.modulate = Color(1,1,1)
func _on_restart_button_mouse_entered(): restart.modulate = HOVER_MODULATE
func _on_restart_button_mouse_exited(): restart.modulate = Color(1,1,1)
func _on_menu_button_mouse_entered(): menu.modulate = HOVER_MODULATE
func _on_menu_button_mouse_exited(): menu.modulate = Color(1,1,1)
func _on_quit_button_mouse_entered(): quit.modulate = HOVER_MODULATE
func _on_quit_button_mouse_exited(): quit.modulate = Color(1,1,1)
