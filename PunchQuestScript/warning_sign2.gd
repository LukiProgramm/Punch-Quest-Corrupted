extends Node2D

@onready var texture: Sprite2D = $texture2
@onready var area_sign: Area2D = $area_sign2

const lines : Array[String] = [
	"Olá novamente aventureiro!",
	"É bom ver você de novo",
	"Espero que esteja pronto",
	"Para o grande desafio final!",
	"Pequeno aventureiro...",
	"...LUTE!",
]

func _unhandled_input(event: InputEvent) -> void:
	if area_sign.get_overlapping_bodies().size() > 0:
		texture.show()
		if event.is_action_pressed("interact") and !DialogManager.is_message_active:
			texture.hide()
			DialogManager.start_message(global_position, lines)
	else:
		texture.hide()
		if DialogManager.dialog_box != null:
			DialogManager.dialog_box.queue_free()
			DialogManager.is_message_active = false
