extends Area2D

@onready var anim = $anim                     # AnimatedSprite2D
@onready var position_spawn = $position_spawn  # Marker2D
@onready var audio_checkpoint = $checkpoint_sfx # AudioStreamPlayer

var is_active = false

func _on_body_entered(body: Node2D) -> void:
	if body.name != "player" or is_active:
		return
	activate_checkpoint()

func activate_checkpoint():
	Globals.checkpoint_position = $position_spawn.global_position
	Globals.has_checkpoint = true
	Globals.initial_position_spawn = position_spawn.global_position
	anim.play("raising")
	audio_checkpoint.play()
	is_active = true

func _on_anim_animation_finished() -> void:
	if anim.animation == "raising":
		anim.play("checked")
