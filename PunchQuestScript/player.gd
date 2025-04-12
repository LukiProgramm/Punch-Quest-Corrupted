extends CharacterBody2D

const SPEED = 130
const JUMP_VELOCITY = -350
const GRAVITY = 800
const KNOCKBACK_FORCE = 250
const MAX_LIFE = 25
const GAME_OVER_SCENE = "res://scenes/game_over.tscn"

var life = MAX_LIFE
var is_attacking = false
var is_blocking = false
var is_hurt = false
var is_dead = false
var facing_right = true
var can_super_punch = true

@onready var anim = $anim
@onready var texture = $texture
@onready var hitbox = $hitbox
@onready var hurtbox = $hurtbox
@onready var camera = $camera
@onready var HealthBar = $"../HUD/Health/Bar"

@onready var snd_jump = $jump
@onready var snd_punch = $punch
@onready var snd_super_punch = $super_punch
@onready var snd_death = $death
@onready var snd_hurt = $hurt
@onready var snd_walking = $walking
@onready var snd_block = $block

func _ready():
	if not hitbox.is_connected("area_entered", Callable(self, "_on_hitbox_area_entered")):
		hitbox.connect("area_entered", _on_hitbox_area_entered)
	if not hurtbox.is_connected("area_entered", Callable(self, "_on_hurtbox_area_entered")):
		hurtbox.connect("area_entered", _on_hurtbox_area_entered)

	Globals.player = self

	if Globals.respawn_on_checkpoint:
		global_position = Globals.checkpoint_position - Vector2(0, 10)
		life = MAX_LIFE
		is_dead = false
		Globals.respawn_on_checkpoint = false
	else:
		life = Globals.life

	update_health_bar()

func _physics_process(_delta):
	if is_dead:
		return
	handle_movement(_delta)
	handle_animation()

func handle_movement(delta):
	if is_attacking or is_blocking or is_hurt:
		velocity.x = 0
	else:
		var direction = Input.get_axis("ui_left", "ui_right")
		velocity.x = direction * SPEED

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = JUMP_VELOCITY
			snd_jump.play()

	move_and_slide()

	if velocity.x != 0:
		facing_right = velocity.x > 0
		texture.flip_h = not facing_right

func handle_animation():
	if is_dead:
		stop_walking_sound()
		return
	if is_hurt:
		anim.play("hurt")
		stop_walking_sound()
	elif is_blocking:
		anim.play("block")
		stop_walking_sound()
	elif is_attacking:
		stop_walking_sound()
	elif not is_on_floor():
		anim.play("jump_fall")
		stop_walking_sound()
	elif velocity.x != 0:
		anim.play("run")
		if not snd_walking.playing:
			snd_walking.play()
	else:
		anim.play("idle")
		stop_walking_sound()

func stop_walking_sound():
	if snd_walking.playing:
		snd_walking.stop()

func _input(event):
	if is_dead:
		return

	if event.is_action_pressed("punch") and not is_attacking and not is_blocking:
		punch()
	elif event.is_action_pressed("super_punch") and not is_attacking and not is_blocking and can_super_punch:
		super_punch()
	elif event.is_action_pressed("block") and not is_attacking:
		is_blocking = true
	elif event.is_action_released("block"):
		is_blocking = false

func punch():
	is_attacking = true
	snd_punch.play()
	anim.play("punch")
	await anim.animation_finished
	is_attacking = false

func super_punch():
	is_attacking = true
	can_super_punch = false
	snd_super_punch.play()
	anim.play("super_punch")
	await anim.animation_finished
	is_attacking = false
	await get_tree().create_timer(2.5).timeout
	can_super_punch = true

func _on_hitbox_area_entered(area):
	if area.has_method("take_damage"):
		var damage = 15 if anim.current_animation == "super_punch" else 5
		area.take_damage(damage)

func _on_hurtbox_area_entered(area):
	if is_hurt or is_dead:
		return
	if area.has_method("get_damage"):
		var damage = area.get_damage()
		if is_blocking:
			snd_block.play()
		take_damage(damage)

func take_damage(damage):
	if is_dead:
		return

	life = max(life - damage, 0)
	Globals.life = life
	update_health_bar()

	if life <= 0:
		die()
		return

	snd_hurt.play()
	is_hurt = true
	anim.play("hurt")
	velocity = Vector2((KNOCKBACK_FORCE if not facing_right else -KNOCKBACK_FORCE), -100)
	await anim.animation_finished
	is_hurt = false

func update_health_bar():
	if HealthBar:
		var percent = float(life) / MAX_LIFE
		HealthBar.size.x = percent * 100.0

func die():
	if is_dead:
		return

	Globals.life = 0
	Globals.current_lives -= 1
	is_dead = true
	stop_walking_sound()
	snd_death.play()
	anim.play("death")

	await get_tree().create_timer(0.1).timeout
	await snd_death.finished

	if Globals.current_lives <= 0:
		get_tree().change_scene_to_file(GAME_OVER_SCENE)
	else:
		Globals.respawn_on_checkpoint = true
		get_tree().reload_current_scene()

func handle_death_zone():
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	global_position = Globals.checkpoint_position
	life = MAX_LIFE
	Globals.life = life
	update_health_bar()
	anim.play("hurt")
	await get_tree().create_timer(0.2).timeout
	is_dead = false

# Parâmetros não usados são prefixados com "_" para evitar avisos
func _on_hitbox_body_entered(_body):
	pass

func _on_hitbox_left_body_entered(_body):
	pass
