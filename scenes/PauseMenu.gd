extends VBoxContainer

signal resume_game

@onready var resume := $ResumeButton
@onready var settings := $SettingsButton
@onready var restart := $RestartButton
@onready var menu := $MenuButton
@onready var quit := $QuitButton
@onready var audiostream := $AudioStreamPlayer

var uiHoverSound = preload("res://assets/sounds/UI_Hover_Click.mp3")
var uiClickSound = preload("res://assets/sounds/UI_Click.mp3")

const HOVER_MODULATE := Color(0.5,0.5,0.5)

func show_menu(retryMode: bool) -> void:
	print("Show menu")
	restart.visible = retryMode
	resume.visible = !retryMode
	visible = true

func hide_menu() -> void:
	visible = false

# When resume is pressed, close the menu
func _on_resume_button_pressed():
	emit_signal("resume_game")
	# Unhighlight the button
	resume.modulate = Color(1,1,1)

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
func _on_resume_button_mouse_entered():
	resume.modulate = HOVER_MODULATE
	_play_hover_sound()
func _on_resume_button_mouse_exited(): resume.modulate = Color(1,1,1)
func _on_settings_button_mouse_entered():
	settings.modulate = HOVER_MODULATE
	_play_hover_sound()
func _on_settings_button_mouse_exited(): settings.modulate = Color(1,1,1)
func _on_restart_button_mouse_entered():
	restart.modulate = HOVER_MODULATE
	_play_hover_sound()
func _on_restart_button_mouse_exited(): restart.modulate = Color(1,1,1)
func _on_menu_button_mouse_entered():
	menu.modulate = HOVER_MODULATE
	_play_hover_sound()
func _on_menu_button_mouse_exited(): menu.modulate = Color(1,1,1)
func _on_quit_button_mouse_entered():
	quit.modulate = HOVER_MODULATE
	_play_hover_sound()
func _on_quit_button_mouse_exited(): quit.modulate = Color(1,1,1)

# Play click on hover
func _play_hover_sound() -> void: 
	audiostream.stream = uiHoverSound
	audiostream.play()
