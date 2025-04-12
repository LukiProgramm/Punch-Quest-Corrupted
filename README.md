# Punch Quest – Explicação dos Scripts

---

## 📌 Introdução

**Punch Quest** é um jogo de ação e plataforma 2D desenvolvido na engine **Godot 4.0**, no qual o jogador controla um personagem que luta contra inimigos utilizando jabs e diretos do box, socos de forma geral.

---

## 🧠 Estrutura Geral Dos Scripts

### **Autoloads (Singletons):**
- **`globals.gd`**: Gerencia as variáveis globais como vidas, checkpoints, músicas etc.
- **`dialog_manager.gd`**: Controla o sistema de diálogos do jogo.

### **Cena Principal:**
- **`world.tscn`**: Arquivo principal que contém o mundo do jogo.

### **Outras Cenas Importantes:**
- **`title_screen.tscn`**: Tela inicial do jogo.
- **`pause_menu.tscn`**: Tela de pausa.
- **`game_over.tscn`**: Tela de game over.
- **HUD**: Interface que mostra a vida do personagem.
- **Checkpoints**: Pontos de respawn.
- **Plataformas móveis e que caem.**
- **Placas interativas com texto (`warning_sign` e `warning_sign2`).**

---

## 📂 Lista de Scripts Explicados

1. **`player.gd`** – Gerencia o personagem principal e suas ações.
2. **`globals.gd`** – Variáveis e estados globais do jogo.
3. **`dialog_manager.gd`** – Sistema de gerenciamento de diálogos.
4. **`dialog_box.gd`** – Sistema de exibição de caixas de diálogo.
5. **`health.gd`** – Gerenciamento da vida dos personagens.
6. **`game_over.gd`** – Tela de Game Over.
7. **`pause_menu.gd`** – Tela de pausa.
8. **`title_screen.gd`** – Tela inicial.
9. **`control.gd`** – Movimentação e navegação dos menus.
10. **`checkpoint.gd`** – Sistema de checkpoints.
11. **`falling_platform.gd`** – Lógica para plataformas que caem.
12. **`move_platform.gd`** – Lógica para plataformas móveis.
13. **`spikes-area.gd`** – Área de espinhos que causa dano.
14. **`warning_sign.gd`** e **`warning_sign2.gd`** – Placas de aviso interativas.
15. **`bear.gd`** – Script do inimigo urso, utilizando máquina de estados.

---

## 📘 Script por Script

Abaixo, detalhamos cada script, explicando suas funções, variáveis e lógica.

---

### 3. **`dialog_manager.gd`**

```gdscript
extends Node  # Script autoload para gerenciar diálogos e avisos, garantindo o funcionamento integrado do dialog_box e warning_sign.

@onready var dialog_box_scene = preload("res://prefabs/dialog_box.tscn")
var message_lines: Array[String] = []
var current_line = 0
var dialog_box
var dialog_box_position := Vector2.ZERO
var is_message_active := false
var can_advance_message := false

func start_message(position: Vector2, lines: Array[String]):
    if is_message_active:
        return
    message_lines = lines
    dialog_box_position = position
    show_text()
    is_message_active = true

func show_text():
    dialog_box = dialog_box_scene.instantiate()
    dialog_box.text_display_finished.connect(_on_all_text_displayed)
    get_tree().root.add_child(dialog_box)
    dialog_box.global_position = dialog_box_position
    dialog_box.display_text(message_lines[current_line])
    can_advance_message = false

func _on_all_text_displayed():
    can_advance_message = true

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("advance_message") and is_message_active and can_advance_message:
        dialog_box.queue_free()
        current_line += 1
        if current_line >= message_lines.size():
            is_message_active = false
            current_line = 0
        else:
            show_text()
```

---

### 4. **`dialog_box.gd`**

```gdscript
extends MarginContainer

@onready var text_label: Label = $label_margin/text_label
@onready var letter_timer_display: Timer = $letter_timer_display
@onready var type_sfx: AudioStreamPlayer = $type_sfx

const MAX_WIDTH = 256
var text: String = ""
var letter_index = 0
var letter_display_timer = 0.07
var space_display_timer = 0.05
var punctuaction_display_timer = 0.2

signal text_display_finished()

func display_text(text_to_display: String):
    text = text_to_display
    letter_index = 0
    text_label.text = text_to_display
    await resized
    custom_minimum_size.x = min(size.x, MAX_WIDTH)

    if size.x > MAX_WIDTH:
        text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
        await resized
        custom_minimum_size.y = size.y

    global_position.x -= size.x / 2
    global_position.y -= size.y + 24
    text_label.text = ""
    display_letter()

func display_letter():
    if letter_index >= text.length():
        text_display_finished.emit()
        return

    text_label.text += text[letter_index]
    if text[letter_index] != " ":
        type_sfx.play()

    letter_index += 1
    if letter_index < text.length():
        match text[letter_index]:
            "!", "?", ",", ".":
                letter_timer_display.start(punctuaction_display_timer)
            " ":
                letter_timer_display.start(space_display_timer)
            _:
                letter_timer_display.start(letter_display_timer)

func _on_letter_timer_display_timeout() -> void:
    display_letter()
```

---

### 5. **`health.gd`**

```gdscript
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
        anim.play("death")

func update_bar():
    var percent := float(current_life) / float(max_life)
    bar.scale.x = percent
```

---

### 6. **`game_over.gd`**

```gdscript
extends Control

@onready var reset_btn: Button = $VBoxContainer/reset_btn
@onready var try_again_btn: Button = $VBoxContainer/try_again_btn
@onready var quit_btn: Button = $VBoxContainer/quit_btn

func _ready() -> void:
    if Globals.current_checkpoint != Globals.initial_position_spawn and null:
        try_again_btn.grab_focus()
        try_again_btn.disabled = true
    else:
        reset_btn.grab_focus()
        try_again_btn.disabled = false

func try_again():
    print(Globals.last_scene)
    get_tree().change_scene_to_file(Globals.last_scene)
    await get_tree().tree_changed
    Globals.reset_var(true, true, false)
    Globals.respawn_player()

func reset():
    get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func quit():
    get_tree().quit()

func _on_reset_btn_pressed() -> void:
    reset()

func _on_quit_btn_pressed() -> void:
    quit()

func _on_try_again_btn_pressed() -> void:
    try_again()
```

---

### 7. **`pause_menu.gd`**

Gerencia a interface de pausa do jogo. Permite ao jogador pausar o jogo, continuar ou sair para o menu principal.

```gdscript
extends CanvasLayer

# Referências para os botões no menu de pausa
@onready var pause_btn: Button = $menu_holder/resume_btn

# Função chamada quando a cena é carregada
func _ready() -> void:
    # Inicialmente, a interface de pausa é escondida
    visible = false

# Captura inputs não tratados
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        # Ativa a interface de pausa
        visible = true
        get_tree().paused = true
        pause_btn.grab_focus()

# Callback acionado ao pressionar o botão "resume"
func _on_resume_btn_pressed() -> void:
    pause_game()

# Callback acionado ao pressionar o botão "quit"
func _on_quit_btn_pressed() -> void:
    quit_game()

# Função para desativar o menu de pausa e continuar o jogo
func pause_game():
    get_tree().paused = false
    visible = false

# Função para finalizar o jogo
func quit_game():
    get_tree().quit()
```

---

### 8. **`title_screen.gd`**

Gerencia a tela de título, onde o jogador pode iniciar o jogo, visualizar os créditos ou sair.

```gdscript
extends Control

# Referência ao botão "Iniciar"
@onready var start_btn = $MarginContainer/HBoxContainer/VBoxContainer/start_btn

# Função chamada quando a cena é carregada
func _ready() -> void:
    # Define o foco inicial no botão "Iniciar"
    start_btn.grab_focus()
    Globals.reset_game()

# Callback acionado ao pressionar "Iniciar"
func _on_start_btn_pressed() -> void:
    start()

# Callback acionado ao pressionar "Créditos"
func _on_credits_btn_pressed() -> void:
    show_credits()

# Callback acionado ao pressionar "Sair"
func _on_quit_btn_pressed() -> void:
    quit()

# Inicia o jogo
func start():
    Globals.reset_game()
    get_tree().change_scene_to_file("res://levels/world.tscn")

# Mostra os créditos (implementação futura)
func show_credits():
    pass

# Sai do jogo
func quit():
    get_tree().quit()
```

---

### 9. **`control.gd`**

Script utilizado para movimentação e seleção de opções nos menus.

```gdscript
extends Node

# Funções utilizadas para manipular botões e navegação
func _ready():
    pass  # Este script é um placeholder para funcionalidades de controle.

func move_button_menu():
    pass  # Função para movimentar o menu.

func select_button_menu():
    pass  # Função para selecionar opções no menu.
```

---

### 10. **`checkpoint.gd`**

Gerencia o comportamento dos checkpoints no jogo. Quando o jogador passa em um checkpoint, a posição é salva para respawn.

```gdscript
extends Area2D

# Referências aos nós
@onready var anim = $anim
@onready var position_spawn = $position_spawn
@onready var audio_checkpoint = $checkpoint_sfx

# Indica se o checkpoint já foi ativado
var is_active = false

# Função acionada ao entrar na área do checkpoint
func _on_body_entered(body: Node2D) -> void:
    if body.name != "player" or is_active:
        return
    activate_checkpoint()

# Ativa o checkpoint
func activate_checkpoint():
    Globals.checkpoint_position = $position_spawn.global_position
    Globals.has_checkpoint = true
    Globals.initial_position_spawn = position_spawn.global_position
    anim.play("raising")
    audio_checkpoint.play()
    is_active = true

# Callback para finalizar a animação do checkpoint
func _on_anim_animation_finished() -> void:
    if anim.animation == "raising":
        anim.play("checked")
```

---

### 11. **`falling_platform.gd`**

Controla plataformas que caem quando o jogador pisa nelas e se reinicializam após um tempo.

```gdscript
extends AnimatableBody2D

# Referências e variáveis
@onready var respawn_timer := $respawn_timer as Timer
@onready var anim := $anim as AnimationPlayer
@onready var respawn_position := global_position
@onready var texture: Sprite2D = $sprite

@export var reset_timer := 3.0
@export var is_green: bool = false

var velocity := Vector2.ZERO
var gravity := 980
var is_triggered := false

# Configurações iniciais
func _ready() -> void:
    set_physics_process(false)
    texture.texture = preload("res://assets/brick-pieces/falling-platform-green.png") if is_green else preload("res://assets/brick-pieces/falling-platform-brown.png")
    $trigger_area.body_entered.connect(_on_trigger_area_body_entered)

# Processamento de física
func _physics_process(delta: float) -> void:
    velocity.y += gravity * delta
    position += velocity * delta

# Ativa a queda da plataforma
func _on_trigger_area_body_entered(body: Node) -> void:
    if body is CharacterBody2D and not is_triggered:
        is_triggered = true
        anim.play("shake")
        velocity = Vector2.ZERO
        respawn_timer.start(reset_timer)

# Callback para finalizar a animação de queda
func _on_anim_animation_finished(anim_name: StringName) -> void:
    if anim_name == "shake":
        set_physics_process(true)

# Reinicia a plataforma
func _on_respawn_timer_timeout() -> void:
    set_physics_process(false)
    global_position = respawn_position
    velocity = Vector2.ZERO
    if is_triggered:
        create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT).tween_property($sprite, "scale", Vector2(1, 1), 0.2).from(Vector2(0, 0))
        is_triggered = false
```

---

### 12. **`move_platform.gd`**

Controla plataformas que se movem entre dois pontos de forma contínua.

```gdscript
extends Node2D

# Constantes e variáveis
const WAIT_DURATION := 1.0
@onready var plataform := $platform as AnimatableBody2D

@export var move_speed := 3.0
@export var distance := 192
@export var move_horizontal := true

var follow := Vector2.ZERO
var plataform_center := 16

# Configurações iniciais
func _ready() -> void:
    move_plataform()

# Processamento de movimento
func _physics_process(_delta: float) -> void:
    plataform.position = plataform.position.lerp(follow, 0.5)

# Controla o movimento da plataforma
func move_plataform():
    var move_direction = Vector2.RIGHT * distance if move_horizontal else Vector2.UP * distance
    var duration = move_direction.length() / float(move_speed * plataform_center)
    create_tween().set_loops().tween_property(self, "follow", move_direction, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT).set_delay(WAIT_DURATION).tween_property(self, "follow", Vector2.ZERO, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT).set_delay(WAIT_DURATION)
```

---

### 13. **`spikes-area.gd`**

Gerencia uma área de armadilha composta por espinhos. Quando o jogador entra nesta área, ele sofre dano massivo, resultando em morte instantânea.

```gdscript
extends Area2D

# Referência à posição anterior do jogador, usada para respawn
@onready var last_position: Marker2D = $"../last_position"

# Configuração da forma de colisão
@onready var collision: CollisionShape2D = $collision
@onready var sprite: Sprite2D = $spikes

# Configura a área de detecção com base no tamanho do sprite
func _ready() -> void:
    var size: Vector2
    if sprite.region_enabled:
        size = sprite.region_rect.size
    else:
        var tex: Texture2D = sprite.texture
        if tex:
            size = tex.get_size()

    var shape = RectangleShape2D.new()
    shape.size = size
    collision.shape = shape

# Detecta entrada do jogador na área
func _on_body_entered(body):
    if body.name == "player":
        body.take_damage(9999)  # Aplica dano massivo
```

---

### 14. **`warning_sign.gd`**

Exibe mensagens de instrução ao jogador ao interagir com placas de aviso.

```gdscript
extends Node2D

# Referências aos nós
@onready var texture: Sprite2D = $texture
@onready var area_sign: Area2D = $area_sign

# Mensagens exibidas ao jogador
const lines: Array[String] = [
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

# Detecta interação do jogador com a placa de aviso
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
```

---

### 15. **`warning_sign2.gd`**

Funciona de forma semelhante ao `warning_sign.gd`, mas com mensagens e comportamento ajustados para um aviso diferente.

```gdscript
extends Node2D

# Referências aos nós
@onready var texture: Sprite2D = $texture2
@onready var area_sign: Area2D = $area_sign2

# Mensagens exibidas ao jogador
const lines: Array[String] = [
    "Olá novamente aventureiro!",
    "É bom ver você de novo",
    "Espero que esteja pronto",
    "Para o grande desafio final!",
    "Pequeno aventureiro...",
    "...LUTE!",
]

# Detecta interação do jogador com a placa de aviso
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
```

---

### 16. **`bear.gd`**

Gerencia o comportamento do inimigo "urso" utilizando uma máquina de estados (state machine). Cada estado define ações e transições específicas, como patrulhar, atacar, tomar dano e morrer.

```gdscript
extends CharacterBody2D

# Parâmetros do urso
@export var max_health := 30
@export var move_speed := 40
@export var attack_damage := 5
@export var attack_range := 16
@export var attack_cooldown := 1.2

# Variáveis gerais
var current_health := max_health
var player
var is_dead := false

# Referências aos nós
@onready var anim: AnimationPlayer = $anim
@onready var sprite: Sprite2D = $sprite
@onready var hitbox: Area2D = $hitbox
@onready var hurtbox: Area2D = $hurtbox
@onready var cooldown_timer: Timer = $cooldown_timer
@onready var player_detector: RayCast2D = $player_detector
@onready var hit_sfx: AudioStreamPlayer = $hit_sfx

# Estados da máquina de estados
enum State { IDLE, WALKING, ATTACKING, HURT, DEAD }
var state: State = State.IDLE

# Configurações iniciais
func _ready():
    current_health = max_health
    hitbox.connect("area_entered", _on_hitbox_area_entered)
    hurtbox.connect("area_entered", _on_hurtbox_area_entered)
    cooldown_timer.wait_time = attack_cooldown
    cooldown_timer.one_shot = true

# Processamento de estados
func _physics_process(_delta):
    match state:
        State.IDLE:
            handle_idle_state()
        State.WALKING:
            handle_walking_state()
        State.ATTACKING:
            handle_attacking_state()
        State.HURT:
            handle_hurt_state()
        State.DEAD:
            handle_dead_state()

    move_and_slide()

# Estados específicos
func handle_idle_state():
    if player_detector.is_colliding():
        var collider = player_detector.get_collider()
        if collider and collider.is_in_group("player"):
            player = collider
            change_state(State.WALKING)

func handle_walking_state():
    if not player or !player_detector.is_colliding():
        change_state(State.IDLE)
        return
    var direction = sign(player.global_position.x - global_position.x)
    sprite.flip_h = direction < 0
    player_detector.scale.x = direction
    if global_position.distance_to(player.global_position) <= attack_range:
        change_state(State.ATTACKING)
    else:
        velocity.x = direction * move_speed
        anim.play("walking")

func handle_attacking_state():
    if cooldown_timer.is_stopped():
        anim.play("attack")
        cooldown_timer.start()

func handle_hurt_state():
    velocity.x = 0

func handle_dead_state():
    velocity.x = 0

# Função para alterar estados
func change_state(new_state: State):
    if state == new_state:
        return
    state = new_state
    match state:
        State.IDLE:
            velocity.x = 0
            anim.play("idle")
        State.WALKING:
            anim.play("walking")
        State.ATTACKING:
            velocity.x = 0
        State.HURT:
            anim.play("hurt")
        State.DEAD:
            anim.stop()

# Callback acionado ao final das animações
func _on_anim_animation_finished(anim_name):
    match anim_name:
        "attack":
            if state == State.ATTACKING:
                change_state(State.WALKING)
        "hurt":
            if state == State.HURT and current_health > 0:
                change_state(State.WALKING)

# Detecta ataques do urso
func _on_hitbox_area_entered(area):
    if not area.is_in_group("player_hurtbox"):
        return
    if player and not is_dead:
        player.take_damage(attack_damage)

# Detecta quando o urso sofre dano
func _on_hurtbox_area_entered(area):
    if area.is_in_group("player_hitbox") and not is_dead:
        take_damage(area.damage)

# Aplica dano ao urso
func take_damage(amount):
    if is_dead:
        return
    current_health -= amount
    if current_health <= 0:
        die()
    else:
        change_state(State.HURT)
        hit_sfx.play()

# Gerencia a morte do urso
func die():
    is_dead = true
    change_state(State.DEAD)
    queue_free()
```

---

## 🏁 FIM DO DOCUMENTO

Esse é o fim para os exploradores do código do **Punch Quest**! Este README foi elaborado para facilitar o entendimento dos scripts e da estrutura do projeto. Caso tenha dúvidas ou sugestões, sinta-se à vontade para contribuir ou abrir uma issue no repositório. 

👉 **[Clique aqui para baixar o jogo](https://www.dropbox.com/scl/fi/68s3et88llcmjg0of7zlf/Punch-Quest.rar?rlkey=1a7ujqvuc8c6onpb8yuua2hrw&e=1&st=g71c3ey3&dl=0)** 🎮
