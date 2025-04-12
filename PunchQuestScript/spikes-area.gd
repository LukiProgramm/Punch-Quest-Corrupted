extends Area2D

@onready var last_position: Marker2D = $"../last_position"
@onready var collision: CollisionShape2D = $collision
@onready var sprite: Sprite2D = $spikes

func _ready() -> void:
	var size: Vector2

	# Se a região estiver ativada, usamos o tamanho da região
	if sprite.region_enabled:
		size = sprite.region_rect.size
	else:
		var tex: Texture2D = sprite.texture
		if tex:
			size = tex.get_size()
	
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape

func _on_body_entered(body):
	if body.name == "player":
		body.take_damage(9999)  # Morte instantânea
