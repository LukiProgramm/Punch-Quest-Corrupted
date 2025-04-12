extends Control

@onready var start_btn = $MarginContainer/HBoxContainer/VBoxContainer/start_btn as Button
@onready var credits_btn = $MarginContainer/HBoxContainer/VBoxContainer/credits_btn as Button
@onready var quit_btn = $MarginContainer/HBoxContainer/VBoxContainer/quit_btn as Button
@onready var sfx = $sfx as AudioStreamPlayer

@export var initial_life := 20

func _ready() -> void:
	start_btn.grab_focus()
	Globals.life = initial_life

# Botões
func _on_start_btn_pressed() -> void:
	select_button_menu()
	Globals.reset_var(true, true, false)
	get_tree().change_scene_to_file("res://levels/1-1.tscn")

func _on_credits_btn_pressed() -> void:
	select_button_menu()
	show_credits()

func _on_quit_btn_pressed() -> void:
	select_button_menu()
	get_tree().quit()

# Efeitos sonoros
func move_button_menu():
	sfx.stream = preload("res://assets/audios/menu-button-88360.mp3")
	sfx.play()

func select_button_menu():
	sfx.stream = preload("res://assets/audios/rizz-sound-effect.mp3")
	sfx.volume_db = 10
	sfx.play()

# Detectar navegação nos botões
func _on_start_btn_button_down(): move_button_menu()
func _on_credits_btn_button_down(): move_button_menu()
func _on_quit_btn_button_down(): move_button_menu()
