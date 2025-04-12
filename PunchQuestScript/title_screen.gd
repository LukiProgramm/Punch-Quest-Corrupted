extends Control

@onready var start_btn = $MarginContainer/HBoxContainer/VBoxContainer/start_btn

func _ready() -> void:
	start_btn.grab_focus()
	Globals.reset_game()

func _on_start_btn_pressed() -> void:
	start()

func _on_credits_btn_pressed() -> void:
	show_credits()

func _on_quit_btn_pressed() -> void:
	quit()

func start():
	Globals.reset_game()
	get_tree().change_scene_to_file("res://levels/world.tscn")
	select_button_menu()

func show_credits():
	# Implemente aqui se quiser mostrar os créditos
	pass

func quit():
	select_button_menu()
	get_tree().quit()

func move_button_menu(): pass
func select_button_menu(): pass

func _on_start_btn_button_up(): move_button_menu()
func _on_start_btn_button_down(): move_button_menu()
func _on_credits_btn_button_down(): move_button_menu()
func _on_credits_btn_button_up(): move_button_menu()
func _on_quit_btn_button_down(): move_button_menu()
func _on_quit_btn_button_up(): move_button_menu()
