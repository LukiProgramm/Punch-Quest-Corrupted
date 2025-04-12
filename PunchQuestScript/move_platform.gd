extends Node2D

# Tempo de espera (em segundos) antes de iniciar e entre os movimentos
const WAIT_DURATION := 1.0

# Referência para o nó da plataforma que será movida
@onready var plataform := $platform as AnimatableBody2D

# Velocidade do movimento da plataforma
@export var move_speed := 3.0

# Distância que a plataforma vai se mover (em pixels)
@export var distance := 192

# Define se a plataforma vai se mover na horizontal (true) ou vertical (false)
@export var move_horizontal := true

# Posição para onde a plataforma irá "seguir"
var follow := Vector2.ZERO

# Fator usado para ajustar a velocidade com base no centro da plataforma (pode ajustar conforme tamanho real)
var plataform_center := 16


# Função chamada ao iniciar a cena
func _ready() -> void:
	move_plataform()  # Inicia o movimento da plataforma


# Função chamada a cada frame de física (60fps)
func _physics_process(_delta: float) -> void:
	# Interpola suavemente a posição da plataforma até o destino (follow)
	plataform.position = plataform.position.lerp(follow, 0.5)


# Função que cria o movimento da plataforma com Tween
func move_plataform():
	# Define a direção do movimento: horizontal ou vertical
	var move_direction = Vector2.RIGHT * distance if move_horizontal else Vector2.UP * distance

	# Calcula o tempo necessário para completar o movimento com base na distância e velocidade
	var duration = move_direction.length() / float(move_speed * plataform_center)

	# Cria um Tween que vai se repetir para sempre (set_loops)
	var plataform_tween = create_tween().set_loops()

	# Movimento da posição atual até o destino (move_direction)
	plataform_tween.tween_property(self, "follow", move_direction, duration)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_delay(WAIT_DURATION)

	# Movimento de volta do destino até a origem (Vector2.ZERO)
	plataform_tween.tween_property(self, "follow", Vector2.ZERO, duration)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_delay(WAIT_DURATION)
