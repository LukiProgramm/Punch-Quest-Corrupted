extends CharacterBody2D

@export var max_health := 30
@export var move_speed := 40
@export var attack_damage := 5
@export var attack_range := 16
@export var attack_cooldown := 1.2

var current_health := max_health
var player
var is_attacking := false
var is_hurt := false
var is_dead := false

@onready var anim: AnimationPlayer = $anim
@onready var sprite: Sprite2D = $sprite
@onready var hitbox: Area2D = $hitbox
@onready var hurtbox: Area2D = $hurtbox
@onready var cooldown_timer: Timer = $cooldown_timer
@onready var player_detector: RayCast2D = $player_detector
@onready var hit_sfx: AudioStreamPlayer = $hit_sfx

func _ready():
	current_health = max_health
	hitbox.connect("area_entered", _on_hitbox_area_entered)
	hurtbox.connect("area_entered", _on_hurtbox_area_entered)
	cooldown_timer.wait_time = attack_cooldown
	cooldown_timer.one_shot = true

func _physics_process(_delta):
	if is_dead or is_attacking or is_hurt:
		velocity.x = 0
		move_and_slide()
		return

	if player_detector.is_colliding():
		var collider = player_detector.get_collider()
		if collider and collider.is_in_group("player"):
			player = collider
			var distance = global_position.distance_to(player.global_position)

			# Direção
			var direction = sign(player.global_position.x - global_position.x)
			sprite.flip_h = direction < 0
			player_detector.scale.x = direction

			# Ataca se estiver perto
			if distance <= attack_range:
				start_attack()
			else:
				# Persegue o player
				velocity.x = direction * move_speed
				anim.play("walking")
		else:
			player = null
			velocity.x = 0
	else:
		velocity.x = 0

	move_and_slide()

func start_attack():
	if cooldown_timer.is_stopped():
		is_attacking = true
		anim.play("attack")
		cooldown_timer.start()

func _on_anim_animation_finished(anim_name):
	if anim_name == "attack":
		is_attacking = false
	elif anim_name == "hurt":
		is_hurt = false
		if current_health > 0:
			anim.play("walking")

func _on_hitbox_area_entered(area):
	if not area.is_in_group("player_hurtbox"):
		return

	if player and not is_dead:
		player.take_damage(attack_damage)

func _on_hurtbox_area_entered(area):
	if area.is_in_group("player_hitbox") and not is_dead:
		take_damage(area.damage)

func take_damage(amount):
	if is_dead: return

	current_health -= amount
	is_hurt = true
	anim.play("hurt")
	hit_sfx.play()

	if current_health <= 0:
		die()

func die():
	is_dead = true
	anim.stop()
	queue_free() # Ou você pode fazer ele desaparecer com animação se quiser
