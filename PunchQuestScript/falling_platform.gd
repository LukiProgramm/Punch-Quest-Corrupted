extends AnimatableBody2D

@onready var respawn_timer := $respawn_timer as Timer
@onready var anim := $anim as AnimationPlayer
@onready var respawn_position := global_position
@onready var texture: Sprite2D = $sprite
@onready var trigger_area := $trigger_area as Area2D

@export var reset_timer := 3.0
@export var is_green: bool = false

var velocity := Vector2.ZERO
var gravity := 980
var is_triggered := false

func _ready() -> void:
	set_physics_process(false)

	# Define a textura da plataforma com base na cor
	if is_green:
		texture.texture = preload("res://assets/brick-pieces/falling-platform-green.png")
	else:
		texture.texture = preload("res://assets/brick-pieces/falling-platform-brown.png")

	# Conectar dinamicamente o sinal do trigger_area
	trigger_area.body_entered.connect(_on_trigger_area_body_entered)

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	position += velocity * delta

func _on_trigger_area_body_entered(body: Node) -> void:
	if body is CharacterBody2D and not is_triggered:
		is_triggered = true
		anim.play("shake")
		velocity = Vector2.ZERO
		# Começa a contagem para a queda (pós-animação)
		respawn_timer.start(reset_timer)

func _on_anim_animation_finished(anim_name: StringName) -> void:
	if anim_name == "shake":
		set_physics_process(true)

func _on_respawn_timer_timeout() -> void:
	set_physics_process(false)
	global_position = respawn_position
	velocity = Vector2.ZERO

	if is_triggered:
		var spawn_tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)
		spawn_tween.tween_property($sprite, "scale", Vector2(1, 1), 0.2).from(Vector2(0, 0))
		is_triggered = false
