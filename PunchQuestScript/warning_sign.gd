extends Node2D

@onready var texture: Sprite2D = $texture
@onready var area_sign: Area2D = $area_sign

const lines : Array[String] = [
	"Olá, aventureiro!",
	"Bem-vindo às planícies de Punch Quest",
	"Aperte Z para socar",
	"Aperte X para bloquear",
	"Aperte C para o super soco",
	"Aperte espaço para pular",
	"Espero que esteja preparado...",
	"Sua jornada está apenas...",
	"...COMEÇANDO!",
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
