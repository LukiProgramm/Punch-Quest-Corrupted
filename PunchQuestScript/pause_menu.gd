extends CanvasLayer

@onready var pause_btn: Button = $menu_holder/resume_btn

func _ready() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		visible = true
		get_tree().paused = true
		pause_btn.grab_focus()

func _on_resume_btn_pressed() -> void:
	pause_game()

func _on_quit_btn_pressed() -> void:
	quit_game()

func pause_game():
	get_tree().paused = false
	visible = false

func quit_game():
	get_tree().quit()
