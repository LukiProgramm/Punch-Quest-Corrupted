extends ColorRect

@onready var bar: ColorRect = $Bar
@onready var anim: AnimatedSprite2D = $anim

var max_life := 20
var current_life := 20

func _ready():
	update_bar()

func take_damage(damage: int):
	current_life = clamp(current_life - damage, 0, max_life)
	update_bar()
	if current_life <= 0:
		anim.play("death") # caso queira animação de morte
		# aqui você pode emitir um sinal ou avisar o Player que ele morreu

func update_bar():
	var percent := float(current_life) / float(max_life)
	bar.scale.x = percent
