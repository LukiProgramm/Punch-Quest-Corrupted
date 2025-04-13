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

Abaixo, detalhamos cada script, explicando suas funções, variáveis e lógica. Os comentários originais foram mantidos no código para facilitar a compreensão.

---

### 1. **`player.gd`**

Gerencia as ações do jogador, incluindo movimento, ataques, bloqueios e interações com o ambiente.

```gdscript
extends CharacterBody2D  # Define que este script é para um personagem que usa corpo físico 2D com movimentação (ex: colisões, gravidade).

# Constantes de movimento e atributos do personagem
const SPEED = 130  # Velocidade horizontal do personagem
const JUMP_VELOCITY = -350  # Força do pulo (valor negativo porque o eixo Y é invertido na Godot)
const GRAVITY = 800  # Gravidade aplicada ao personagem
const KNOCKBACK_FORCE = 250  # Força de recuo ao tomar dano
const MAX_LIFE = 25  # Vida máxima do personagem
const GAME_OVER_SCENE = "res://scenes/game_over.tscn"  # Caminho da cena de Game Over

# Variáveis de estado do personagem
var life = MAX_LIFE  # Vida atual do personagem
var is_attacking = false  # Define se o personagem está atacando
var is_blocking = false  # Define se o personagem está bloqueando
var is_hurt = false  # Define se o personagem está machucado (tomando dano)
var is_dead = false  # Define se o personagem está morto
var facing_right = true  # Direção que o personagem está virado (true = direita)
var can_super_punch = true  # Controle de cooldown para o golpe especial

# Referência para nós filhos do personagem
@onready var anim = $anim  # Nó AnimationPlayer responsável pelas animações
@onready var texture = $texture  # Nó Sprite2D do personagem
@onready var hitbox = $hitbox  # Área de ataque do personagem
@onready var hurtbox = $hurtbox  # Área de colisão para receber dano
@onready var camera = $camera  # Câmera que segue o personagem
@onready var HealthBar = $"../HUD/Health/Bar"  # Barra de vida no HUD

# Nós de áudio (efeitos sonoros do personagem)
@onready var snd_jump = $jump
@onready var snd_punch = $punch
@onready var snd_super_punch = $super_punch
@onready var snd_death = $death
@onready var snd_hurt = $hurt
@onready var snd_walking = $walking
@onready var snd_block = $block

# Função chamada quando a cena é carregada
func _ready():
    # Conecta os sinais de entrada de área para hitbox e hurtbox
    if not hitbox.is_connected("area_entered", Callable(self, "_on_hitbox_area_entered")):
        hitbox.connect("area_entered", _on_hitbox_area_entered)
    if not hurtbox.is_connected("area_entered", Callable(self, "_on_hurtbox_area_entered")):
        hurtbox.connect("area_entered", _on_hurtbox_area_entered)

    # Define o jogador globalmente (para acesso via Globals.player)
    Globals.player = self

    # Lógica de respawn em checkpoint
    if Globals.respawn_on_checkpoint:
        global_position = Globals.checkpoint_position - Vector2(0, 10)  # Move o jogador para a posição do checkpoint
        life = MAX_LIFE
        is_dead = false
        Globals.respawn_on_checkpoint = false
    else:
        life = Globals.life  # Recupera a vida salva na variável global

    update_health_bar()  # Atualiza visualmente a barra de vida no HUD

# Processamento físico a cada frame
func _physics_process(_delta):
    if is_dead:
        return  # Se o personagem estiver morto, nada é processado
    handle_movement(_delta)  # Processa movimento
    handle_animation()  # Processa a animação correspondente

# Função responsável pela movimentação do personagem
func handle_movement(delta):
    # Se estiver atacando, bloqueando ou machucado, não pode se mover
    if is_attacking or is_blocking or is_hurt:
        velocity.x = 0
    else:
        var direction = Input.get_axis("ui_left", "ui_right")  # Retorna -1, 0 ou 1
        velocity.x = direction * SPEED  # Define a velocidade horizontal

    # Aplica gravidade quando está no ar
    if not is_on_floor():
        velocity.y += GRAVITY * delta
    else:
        # Se está no chão e pressionar pulo
        if Input.is_action_just_pressed("ui_accept"):
            velocity.y = JUMP_VELOCITY
            snd_jump.play()

    move_and_slide()  # Move o personagem com colisão

    # Inverte o sprite de acordo com a direção
    if velocity.x != 0:
        facing_right = velocity.x > 0
        texture.flip_h = not facing_right

# Função que gerencia animações baseadas no estado do personagem
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

# Para o som de passos
func stop_walking_sound():
    if snd_walking.playing:
        snd_walking.stop()

# Processa inputs do teclado
func _input(event):
    if is_dead:
        return  # Não processa input se estiver morto

    # Ataca com soco comum
    if event.is_action_pressed("punch") and not is_attacking and not is_blocking:
        punch()
    # Ataca com golpe especial (super soco)
    elif event.is_action_pressed("super_punch") and not is_attacking and not is_blocking and can_super_punch:
        super_punch()
    # Ativa bloqueio
    elif event.is_action_pressed("block") and not is_attacking:
        is_blocking = true
    elif event.is_action_released("block"):
        is_blocking = false

# Função para soco comum
func punch():
    is_attacking = true
    snd_punch.play()
    anim.play("punch")
    await anim.animation_finished  # Espera a animação terminar
    is_attacking = false

# Função para golpe especial (super soco)
func super_punch():
    is_attacking = true
    can_super_punch = false  # Ativa cooldown
    snd_super_punch.play()
    anim.play("super_punch")
    await anim.animation_finished
    is_attacking = false
    await get_tree().create_timer(2.5).timeout  # Espera cooldown de 2.5s
    can_super_punch = true

# Detecta colisão da hitbox com inimigos
func _on_hitbox_area_entered(area):
    if area.has_method("take_damage"):
        var damage = 15 if anim.current_animation == "super_punch" else 5
        area.take_damage(damage)  # Chama método do inimigo para aplicar dano

# Detecta quando o jogador é atingido por algo
func _on_hurtbox_area_entered(area):
    if is_hurt or is_dead:
        return
    if area.has_method("get_damage"):
        var damage = area.get_damage()  # Pega o valor de dano da outra área
        if is_blocking:
            snd_block.play()  # Toca som de bloqueio se estiver bloqueando
        take_damage(damage)

# Aplica dano ao jogador
func take_damage(damage):
    if is_dead:
        return

    life = max(life - damage, 0)  # Reduz a vida sem deixar negativa
    Globals.life = life  # Atualiza a vida na variável global
    update_health_bar()

    if life <= 0:
        die()
        return

    snd_hurt.play()
    is_hurt = true
    anim.play("hurt")
    # Aplica knockback leve para trás e para cima
    velocity = Vector2((KNOCKBACK_FORCE if not facing_right else -KNOCKBACK_FORCE), -100)
    await anim.animation_finished
    is_hurt = false

# Atualiza a barra de vida com base na porcentagem
func update_health_bar():
    if HealthBar:
        var percent = float(life) / MAX_LIFE
        HealthBar.size.x = percent * 100.0  # Assume que a largura máxima é 100

# Função chamada ao morrer
func die():
    if is_dead:
        return

    Globals.life = 0
    Globals.current_lives -= 1  # Reduz uma vida global
    is_dead = true
    stop_walking_sound()
    snd_death.play()
    anim.play("death")

    await get_tree().create_timer(0.1).timeout
    await snd_death.finished

    # Vai para o Game Over se não houver vidas
    if Globals.current_lives <= 0:
        get_tree().change_scene_to_file(GAME_OVER_SCENE)
    else:
        # Recarrega a cena atual e volta para o último checkpoint
        Globals.respawn_on_checkpoint = true
        get_tree().reload_current_scene()
```

---

### 2. **`globals.gd`**

```gdscript name=globals.gd
extends Node  # Este script é autoload (singleton) e gerencia dados globais do jogo, como vida, vidas restantes, checkpoints e respawn.

# Constantes definindo limites globais
const MAX_LIFE := 25         # Vida máxima que o jogador pode ter em cada ciclo.
const MAX_LIVES := 3         # Número total de vidas disponíveis antes de ocorrer o Game Over.

# Variáveis globais para gerenciamento do jogo
var life: int = MAX_LIFE         # Armazena a vida atual do jogador, iniciando com o valor máximo.
var current_lives: int = MAX_LIVES # Quantidade atual de vidas disponíveis para o jogador.
var checkpoint_position: Vector2 = Vector2.ZERO  # Guarda a posição do último checkpoint atingido. Inicialmente, não há checkpoint.
var has_checkpoint: bool = false                   # Flag que indica se um checkpoint foi ativado.
var respawn_on_checkpoint := false                # Determina se, ao respawn, o jogador deve ser posicionado no checkpoint.
var player: Node = null                           # Referência ao nó do jogador, a ser definida ao instanciar o personagem na cena.
var last_scene: String = "res://levels/world.tscn" # Caminho da cena atual ou do último nível, usada para recarregar o ambiente ao respawn.
var initial_position_spawn: Vector2 = Vector2.ZERO # Posição inicial de spawn do jogador.

# Função que atualiza a vida do jogador, garantindo que o valor fique entre 0 e MAX_LIFE.
func set_life(value: int) -> void:
    # O uso do 'clamp' assegura que a vida não ultrapasse os limites permitidos.
    life = clamp(value, 0, MAX_LIFE)

# Função que decrementa uma vida do jogador e retorna se ainda há vidas restantes.
func lose_life() -> bool:
    current_lives -= 1
    # Retorna 'true' se ainda houver pelo menos uma vida, 'false' se chegar a zero.
    return current_lives > 0

# Função para resetar variáveis essenciais do jogo de forma flexível.
# Parâmetros:
#   reset_life (padrão: true): Reseta a vida atual para MAX_LIFE.
#   reset_lives (padrão: false): Reseta o contador de vidas para MAX_LIVES.
#   reset_checkpoint (padrão: true): Limpa as informações de checkpoint (posição, flag e respawn).
func reset_var(reset_life := true, reset_lives := false, reset_checkpoint := true) -> void:
    if reset_life:
        life = MAX_LIFE
    if reset_lives:
        current_lives = MAX_LIVES
    if reset_checkpoint:
        checkpoint_position = Vector2.ZERO
        has_checkpoint = false
        respawn_on_checkpoint = false

# Função que reinicializa completamente o estado do jogo,
# chamando reset_var() com todos os parâmetros ativados.
func reset_game() -> void:
    reset_var(true, true, true)

# Função que gerencia o respawn do jogador.
# Passos:
# 1. Se uma instância do jogador existir, ela é removida (queue_free) para evitar duplicação.
# 2. Aguarda o processamento do frame atual para assegurar que a remoção seja concluída.
# 3. Carrega e instancia a cena armazenada em last_scene.
# 4. Libera a cena atual para evitar conflitos e adiciona a nova cena à árvore de nós.
# 5. Define a nova cena como a cena atual do jogo.
func respawn_player():
    if player:
        player.queue_free()
    await get_tree().process_frame

    var world_scene = load(last_scene).instantiate()
    get_tree().current_scene.free()
    get_tree().root.add_child(world_scene)
    get_tree().current_scene = world_scene
```

---

### 3. **`dialog_manager.gd`**

```gdscript name=dialog_manager.gd
extends Node  # Script autoload para gerenciar diálogos e avisos, garantindo o funcionamento integrado do dialog_box e warning_sign.

@onready var dialog_box_scene = preload("res://prefabs/dialog_box.tscn")
# Pré-carrega a cena do dialog_box para otimizar sua instanciação quando necessário.

var message_lines: Array[String] = []
# Array que armazenará todas as linhas de mensagem do diálogo a ser exibido.

var current_line = 0
# Índice que controla qual linha de mensagem está atualmente sendo exibida.

var dialog_box
# Variável que vai guardar a instância da caixa de diálogo (dialog_box) quando ela for criada.

var dialog_box_position := Vector2.ZERO
# Posição global onde a dialog_box será apresentada na tela.

var is_message_active := false
# Flag que indica se um diálogo já está ativo, evitando que novos diálogos sejam iniciados simultaneamente.

var can_advance_message := false
# Flag que indica se o jogador pode avançar para a próxima linha, ou seja, se o texto atual já foi exibido totalmente.

func start_message(position: Vector2, lines: Array[String]):
    # Inicia um novo diálogo:
    # • 'position': Define onde a dialog_box será posicionada na tela.
    # • 'lines': Conjunto de linhas que compõem a mensagem do diálogo.
    if is_message_active:
        return  # Se já houver um diálogo ativo, não faz nada para evitar conflitos.
    message_lines = lines  # Atualiza as linhas de mensagem com o conteúdo recebido.
    dialog_box_position = position  # Define a posição de exibição da dialog_box.
    show_text()  # Exibe a primeira linha do diálogo através da função show_text.
    is_message_active = true  # Marca que um diálogo está ativo.

func show_text():
    # Responsável por criar e exibir a dialog_box com a linha atual do diálogo.
    dialog_box = dialog_box_scene.instantiate()
    # Instancia a dialog_box a partir da cena pré-carregada.
    
    dialog_box.text_display_finished.connect(_on_all_text_displayed)
    # Conecta o sinal que indica o término da exibição do texto ao método _on_all_text_displayed,
    # permitindo saber quando o jogador pode avançar para a próxima linha.
    
    get_tree().root.add_child(dialog_box)
    # Adiciona a dialog_box à raiz da cena para garantir que ela seja exibida corretamente.
    
    dialog_box.global_position = dialog_box_position
    # Posiciona a dialog_box na posição definida anteriormente.
    
    dialog_box.display_text(message_lines[current_line])
    # Chama o método da dialog_box para exibir o texto da linha atual do diálogo.
    
    can_advance_message = false
    # Inicialmente, o jogador não pode avançar até que a dialog_box sinalize que terminou de mostrar o texto.

func _on_all_text_displayed():
    # Callback acionado quando a dialog_box finaliza a exibição do texto.
    can_advance_message = true
    # Libera a possibilidade de avançar para a próxima linha ao permitir que o jogador pressione a ação de avanço.

func _unhandled_input(event: InputEvent) -> void:
    # Processa eventos de input que não foram tratados por outros nós.
    # Verifica se o jogador pressionou a ação "advance_message" enquanto um diálogo está ativo
    # e se a exibição do texto atual foi concluída.
    if event.is_action_pressed("advance_message") and is_message_active and can_advance_message:
        dialog_box.queue_free()
        # Remove a dialog_box atual da cena para prepará-la para a próxima linha.
        
        current_line += 1
        # Avança para a próxima linha do diálogo.
        
        if current_line >= message_lines.size():
            # Se todas as linhas já foram exibidas, encerra o diálogo.
            is_message_active = false
            current_line = 0  # Reseta o índice para possibilitar futuros diálogos.
        else:
            # Se ainda há linhas para exibir, chama novamente a função show_text para montar e exibir a próxima linha.
            show_text()
```

---

### 4. **`dialog_box.gd`**

```gdscript name=dialog_box.gd
extends MarginContainer  # Esse script estende MarginContainer, que facilita o gerenciamento do layout e das margens da caixa de diálogo.

@onready var text_label: Label = $label_margin/text_label  
# Referência ao Label que exibirá o texto. Ele está posicionado dentro de um container chamado "label_margin".
@onready var letter_timer_display: Timer = $letter_timer_display  
# Timer usado para criar o efeito de "digitando" as letras, controlando o intervalo entre cada exibição.
@onready var type_sfx: AudioStreamPlayer = $type_sfx  
# Player de áudio responsável por tocar o som de digitação para cada letra, incrementando o realismo da experiência.

const MAX_WIDTH = 256  
# Largura máxima permitida para a caixa de diálogo. Se o tamanho exceder esse valor, o texto sofre quebra automática.

var text : String = ""  
# Armazena o texto completo que deverá ser exibido na caixa de diálogo.
var letter_index = 0  
# Índice usado para controlar qual letra do texto será exibida a seguir.

var letter_display_timer = 0.07  
# Tempo padrão de atraso (em segundos) para exibir cada letra.
var space_display_timer = 0.05  
# Tempo de atraso específico para espaços, garantindo um fluxo natural sem pausas exageradas.
var punctuaction_display_timer = 0.2  
# Tempo de atraso maior para pontuações (como "!", "?", ",", "."), enfatizando uma pausa para melhor leitura.

signal text_display_finished()  
# Sinal emitido quando todo o texto tiver sido exibido, permitindo que outras partes do jogo respondam a essa conclusão.

func display_text(text_to_display: String):
    # Inicializa a exibição do texto na caixa de diálogo.
    text = text_to_display  # Armazena o texto que será exibido.
    letter_index = 0  # Reinicia o índice para começar a exibição desde a primeira letra.
    text_label.text = text_to_display  
    # Inicialmente, o texto completo é atribuído para que o container se ajuste dinamicamente ao seu tamanho.
    
    await resized  
    # Aguarda que o layout seja ajustado (redimensionado) após definir o texto completo.
    
    custom_minimum_size.x = min(size.x, MAX_WIDTH)  
    # Define a largura mínima da caixa baseada no tamanho atual, mas sem exceder o valor máximo definido por MAX_WIDTH.
    
    if size.x > MAX_WIDTH:
        # Se a largura calculada exceder MAX_WIDTH, ativa a quebra automática de palavras para melhor formatação.
        text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
        await resized  # Aguarda o ajuste do layout após a alteração do autowrap.
        await resized  # Um segundo await garante que o redimensionamento se estabilize.
        custom_minimum_size.y = size.y  
        # Ajusta a altura mínima com base no novo tamanho da caixa.
    
    # Realinha a posição global da caixa de diálogo para centralizá-la e posicioná-la acima do ponto de referência.
    global_position.x -= size.x / 2
    global_position.y -= size.y + 24
    
    text_label.text = ""  
    # Limpa o texto do label para iniciar a exibição com o efeito "máquina de escrever".
    display_letter()  
    # Inicia o processo de exibir cada letra individualmente.

func display_letter():
    # Exibe uma letra do texto de cada vez, gerando o efeito de digitação.
    if letter_index >= text.length():
        # Quando todas as letras já tiverem sido exibidas, emite o sinal informando a conclusão e encerra a função.
        text_display_finished.emit()
        return
    
    # Acrescenta a letra atual ao texto já exibido.
    text_label.text += text[letter_index]
    
    # Se a letra atual não for um espaço, toca o efeito sonoro de digitação.
    if text[letter_index] != " ":
        type_sfx.play()

    letter_index += 1  # Avança para a próxima letra.
    
    # Se ainda houver mais letras a serem exibidas, define o tempo de espera para a próxima chamada,
    # ajustando-o conforme o tipo do próximo caractere.
    if letter_index < text.length():
        match text[letter_index]:
            "!","?",",",".":  # Para caracteres de pontuação, aplica um atraso maior.
                letter_timer_display.start(punctuaction_display_timer)
            " ":  # Para espaços, utiliza um tempo de atraso um pouco menor.
                letter_timer_display.start(space_display_timer)
            _:  # Para quaisquer outros caracteres, utiliza o tempo padrão.
                letter_timer_display.start(letter_display_timer)

func _on_letter_timer_display_timeout() -> void:
    # Callback ativado quando o timer de exibição vence, sinalizando para continuar exibindo a próxima letra.
    display_letter()
```

---

### 5. **`health.gd`**

```gdscript name=health.gd
extends ColorRect  # Este script gerencia a barra de vida, utilizando um ColorRect para representar visualmente a saúde.

@onready var bar: ColorRect = $Bar  
# Referência para o nó "Bar", que é o ColorRect representando a barra de vida propriamente dita.

@onready var anim: AnimatedSprite2D = $anim  
# Referência para o AnimatedSprite2D usado para tocar animações, como a animação de morte.

var max_life := 20  
# Define o valor máximo de vida que o personagem pode ter.

var current_life := 20  
# Armazena a vida atual do personagem, começando no valor máximo.

func _ready():
    # Quando o nó estiver pronto, atualiza a barra de vida para refletir o estado inicial.
    update_bar()

func take_damage(damage: int):
    # Aplica o dano recebido, decrementando a vida atual.
    # O uso de clamp garante que o valor de current_life não fique abaixo de 0 nem acima de max_life.
    current_life = clamp(current_life - damage, 0, max_life)
    
    # Atualiza a barra visual para refletir a nova vida.
    update_bar()
    
    # Se a vida chegar a zero ou menos, aciona a animação de morte.
    if current_life <= 0:
        anim.play("death")  # Toca animação de morte para indicar visualmente que o personagem morreu.
        # Aqui, você pode emitir um sinal ou chamar uma função para notificar que o Player morreu.

func update_bar():
    # Calcula a porcentagem da vida atual em relação ao máximo.
    var percent := float(current_life) / float(max_life)
    # Ajusta a escala horizontal da barra de vida com base nessa porcentagem,
    # permitindo que a barra diminua ou aumente conforme o dano sofrido ou a recuperação de vida.
    bar.scale.x = percent
```

### 6. **`game_over.gd`**

```gdscript name=game_over.gd
extends Control  # Este script controla a interface da tela de Game Over, apresentando opções para resetar o jogo, tentar novamente ou sair.

@onready var reset_btn: Button = $VBoxContainer/reset_btn  
# Referência ao botão que, quando acionado, levará o jogador para a tela de título (reset).

@onready var try_again_btn: Button = $VBoxContainer/try_again_btn  
# Referência ao botão que permite ao jogador retomar o jogo a partir da última cena / checkpoint.

@onready var quit_btn: Button = $VBoxContainer/quit_btn  
# Referência ao botão que, ao ser pressionado, encerra o jogo.

func _ready() -> void:
    # Configura o foco inicial dos botões e a disponibilidade do botão "Tentar Novamente" (try_again_btn)
    # com base na condição de checkpoint. A condição abaixo verifica se o checkpoint atual é diferente da posição inicial.
    # Note que o uso de "and null" parece redundante, mas mantemos conforme o script original.
    if Globals.current_checkpoint != Globals.initial_position_spawn and null:
        # Se existir um checkpoint diferente do ponto inicial, o try_again_btn recebe o foco,
        # porém, é desabilitado, impedindo que o jogador escolha essa opção.
        try_again_btn.grab_focus()
        try_again_btn.disabled = true
    else:
        # Caso contrário, o reset_btn recebe o foco e o try_again_btn fica habilitado,
        # permitindo que o jogador o utilize para tentar novamente.
        reset_btn.grab_focus()
        try_again_btn.disabled = false

func try_again():
    # Função acionada quando o jogador decide tentar novamente.
    # A princípio, imprime o caminho da última cena para fins de depuração.
    print(Globals.last_scene)
    # Altera a cena atual para a última cena registrada em Globals, permitindo retomar o jogo do último ponto.
    get_tree().change_scene_to_file(Globals.last_scene)
    # Aguarda que a árvore de cena seja atualizada antes de prosseguir, garantindo que a mudança seja efetiva.
    await get_tree().tree_changed
    # Reseta variáveis globais essenciais, mantendo o checkpoint ativo (o terceiro parâmetro é false).
    Globals.reset_var(true, true, false)
    # Invoca o processo de respawn do jogador para reiniciar sua posição e estado na cena.
    Globals.respawn_player()

func reset():
    # Reinicia o jogo a partir da tela título.
    # Altera a cena atual para a tela de título, permitindo ao jogador recomeçar o jogo desde o início.
    get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func quit():
    # Encerra o jogo ao chamar o método quit na árvore de cena.
    get_tree().quit()

# Callback para os eventos de clique ou toque nos botões da interface de Game Over.
func _on_reset_btn_pressed() -> void:
    reset()  # Aciona a função reset() quando o botão reset é pressionado.

func _on_reset_touch_pressed() -> void:
    reset()  # Garante que eventos de toque também acionem o reset.

func _on_quit_btn_pressed() -> void:
    quit()  # Chama a função quit() ao pressionar o botão de sair.

func _on_quit_touch_pressed() -> void:
    quit()  # Permite que o toque no botão de sair também encerre o jogo.

func _on_try_again_btn_pressed() -> void:
    try_again()  # Aciona a função try_again() quando o botão tentar novamente é pressionado.

func _on_try_again_touch_pressed() -> void:
    try_again()  # Permite que eventos de toque também acionem o try_again().
```

---

### 7. **`pause_menu.gd`**

```gdscript name=pause_menu.gd
extends CanvasLayer  
# Este script gerencia a interface de pausa do jogo.  
# Ao estender CanvasLayer, garante que os elementos de UI (como botões) sejam renderizados acima de todos os outros nós.

@onready var pause_btn: Button = $menu_holder/resume_btn  
# Referência ao botão de retomar (resume) que fica dentro do nó "menu_holder".  
# Esse botão receberá o foco quando o jogo for pausado.

func _ready() -> void:
    # Inicialmente, a interface de pausa é escondida para que não interfira durante o gameplay.
    visible = false

func _unhandled_input(event: InputEvent) -> void:
    # Função que intercepta inputs que não foram capturados por outros nós.
    # É usada aqui para detectar quando o jogador aciona a ação de pausa.
    if event.is_action_pressed("pause"):
        visible = true         # Torna a interface de pausa visível.
        get_tree().paused = true  
        # Pausa a árvore de cena, interrompendo todas as atualizações de nós, exceto os que 
        # estiverem configurados para funcionar durante a pausa (como as interfaces de usuário).
        pause_btn.grab_focus() 
        # Coloca o foco no botão de retomar para que o jogador possa facilmente continuar o jogo.

func _on_resume_btn_pressed() -> void:
    # Função callback chamada quando o botão de retomar (resume) é pressionado.
    pause_game()  # Chama a função que despausa o jogo e esconde a interface de pausa.

func _on_quit_btn_pressed() -> void:
    # Callback acionada ao pressionar o botão de sair presente na interface de pausa.
    quit_game()  # Chama a função que finaliza o jogo.

func pause_game():
    # Função responsável por resumir o jogo e retirar a interface de pausa.
    get_tree().paused = false  
    # Despausa a árvore de cena, permitindo que todos os nós retomem suas atualizações.
    visible = false  
    # Esconde a interface de pausa, retornando ao gameplay sem interrupções.

func quit_game():
    # Função que encerra a execução do jogo.
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
# Este script implementa o comportamento do inimigo "Bear" utilizando uma máquina de estados (state machine).
# A máquina de estados (state machine) organiza os possíveis estados do inimigo e suas transições,
# facilitando a leitura, manutenção e expansão do comportamento do personagem.

# ============================
# Configurações do inimigo
# ============================

@export var max_health := 30           # Vida máxima do inimigo.
@export var move_speed := 40           # Velocidade de movimentação.
@export var attack_damage := 5         # Dano causado em cada ataque.
@export var attack_range := 16         # Alcance do ataque (distância em que o inimigo pode atacar o jogador).
@export var attack_cooldown := 1.2     # Tempo de recarga entre ataques, em segundos.

# ============================
# Variáveis de estado
# ============================

var current_health := max_health       # Vida atual do inimigo, começa no valor máximo.
var player                             # Referência para o jogador detectado pelo inimigo.
var is_dead := false                   # Controle booleano para verificar se o inimigo está morto.

# ============================
# Referências aos nós da cena
# ============================

@onready var anim: AnimationPlayer = $anim           # Controla as animações do inimigo (idle, walking, attack, hurt, etc.).
@onready var sprite: Sprite2D = $sprite              # Controla a aparência visual do inimigo (permite flip horizontal).
@onready var hitbox: Area2D = $hitbox                # Área que detecta colisões para realizar o ataque.
@onready var hurtbox: Area2D = $hurtbox              # Área que detecta colisões para receber dano.
@onready var cooldown_timer: Timer = $cooldown_timer # Timer que controla o tempo de recarga entre ataques.
@onready var player_detector: RayCast2D = $player_detector  # RayCast que auxilia na detecção do jogador.
@onready var hit_sfx: AudioStreamPlayer = $hit_sfx   # Efeito sonoro tocado quando o inimigo recebe dano.

# ============================
# Máquina de Estados
# ============================

# Definição dos possíveis estados do inimigo usando um enum.
enum State { IDLE, WALKING, ATTACKING, HURT, DEAD }
var state: State = State.IDLE   # O estado inicial do inimigo é o "IDLE" (parado).

# ============================
# Configurações iniciais
# ============================

func _ready():
    # Inicializa a saúde e conecta sinais para detecção de ataques e dano.
    current_health = max_health

    # Conecta sinais para detectar colisões com a hitbox (área de ataque) e hurtbox (área de receber dano).
    hitbox.connect("area_entered", _on_hitbox_area_entered)
    hurtbox.connect("area_entered", _on_hurtbox_area_entered)

    # Configura o tempo de espera do cooldown (tempo entre ataques).
    cooldown_timer.wait_time = attack_cooldown
    cooldown_timer.one_shot = true  # O timer é configurado como "one-shot" para que não repita automaticamente.

# ============================
# Processamento principal
# ============================

func _physics_process(_delta):
    # A cada frame, o comportamento do inimigo é determinado pelo estado atual.
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

    move_and_slide()  # Aplica as leis de física ao movimento do inimigo.

# ============================
# Funções para cada estado
# ============================

func handle_idle_state():
    # Estado "IDLE" (parado): O inimigo está ocioso, esperando detectar o jogador.
    if player_detector.is_colliding():
        var collider = player_detector.get_collider()
        if collider and collider.is_in_group("player"):
            # Se detectar o jogador, salva a referência ao jogador e muda para o estado "WALKING".
            player = collider
            change_state(State.WALKING)

func handle_walking_state():
    # Estado "WALKING" (andando): O inimigo persegue o jogador.
    if not player or !player_detector.is_colliding():
        # Se o jogador não for mais detectado, volta para o estado "IDLE".
        change_state(State.IDLE)
        return

    var distance = global_position.distance_to(player.global_position)
    var direction = sign(player.global_position.x - global_position.x)  # Direção para o jogador (-1 ou 1 no eixo X).

    # Ajusta a orientação do sprite para olhar na direção correta.
    sprite.flip_h = direction < 0
    player_detector.scale.x = direction  # Ajusta a direção do RayCast para "apontar" corretamente.

    if distance <= attack_range:
        # Se o jogador estiver ao alcance, muda para o estado "ATTACKING".
        change_state(State.ATTACKING)
    else:
        # Caso contrário, continua se movendo em direção ao jogador.
        velocity.x = direction * move_speed
        anim.play("walking")

func handle_attacking_state():
    # Estado "ATTACKING" (atacando): O inimigo realiza um ataque.
    if cooldown_timer.is_stopped():
        anim.play("attack")  # Toca a animação de ataque.
        cooldown_timer.start()  # Reinicia o cooldown do ataque.

func handle_hurt_state():
    # Estado "HURT" (machucado): O inimigo interrompe o movimento ao ser atacado.
    velocity.x = 0  # Para o movimento horizontal.

func handle_dead_state():
    # Estado "DEAD" (morto): O inimigo para completamente.
    velocity.x = 0  # Não há movimento no estado "morto".

# ============================
# Função de transição de estados
# ============================

func change_state(new_state: State):
    # Controla a transição entre estados.
    if state == new_state:
        return  # Se o estado atual já for o desejado, não faz nada.

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
            velocity.x = 0
            anim.play("hurt")
        State.DEAD:
            anim.stop()  # Para todas as animações.

# ============================
# Callbacks de animações
# ============================

func _on_anim_animation_finished(anim_name):
    # Função chamada ao final de uma animação.
    if anim_name == "attack" and state == State.ATTACKING:
        change_state(State.WALKING)  # Após o ataque, volta a perseguir o jogador.
    elif anim_name == "hurt" and state == State.HURT and current_health > 0:
        change_state(State.WALKING)  # Após ser machucado, volta a perseguir o jogador.

# ============================
# Detecção de ataques
# ============================

func _on_hitbox_area_entered(area):
    # Função chamada quando a hitbox do inimigo colide com a área de dano do jogador.
    if area.is_in_group("player_hurtbox") and player and not is_dead:
        player.take_damage(attack_damage)  # Aplica dano ao jogador.

# ============================
# Receber dano
# ============================

func _on_hurtbox_area_entered(area):
    # Função chamada quando o inimigo é atingido por algo.
    if area.is_in_group("player_hitbox") and not is_dead:
        take_damage(area.damage)

func take_damage(amount):
    # Aplica dano ao inimigo e gerencia a transição para o estado "HURT" ou "DEAD".
    if is_dead:
        return

    current_health -= amount
    if current_health <= 0:
        die()
    else:
        change_state(State.HURT)
        hit_sfx.play()  # Toca o som de "machucado".

# ============================
# Morte do inimigo
# ============================

func die():
    # Transita para o estado "DEAD" e remove o inimigo da cena.
    is_dead = true
    change_state(State.DEAD)
    queue_free()  # Remove o inimigo da cena.

# ============================
# Detalhes Adicionais
# ============================

# 1. **Máquina de Estados (State Machine):**
#    - Cada estado (IDLE, WALKING, ATTACKING, HURT, DEAD) tem comportamentos isolados.
#    - A transição entre estados é centralizada na função `change_state()`.

# 2. **RayCast2D como Detecção:**
#    - O `player_detector` usa RayCast para detectar a presença do jogador no alcance do inimigo.
#    - Isso permite que o inimigo só reaja se o jogador estiver em sua "linha de visão".

# 3. **Hitbox e Hurtbox:**
#    - A `hitbox` é usada para atacar o jogador.
#    - A `hurtbox` é usada para detectar quando o inimigo recebe ataques.

# 4. **Animações:**
#    - Cada estado tem uma animação específica configurada no `AnimationPlayer`.
#    - O callback `_on_anim_animation_finished` garante transições suaves entre ataques, dano e outros estados.
```

---

## 🏁 FIM DO DOCUMENTO

Esse é o fim para os exploradores do código do **Punch Quest**! Este README foi elaborado para facilitar o entendimento dos scripts e da estrutura do projeto. Caso tenha dúvidas ou sugestões, sinta-se à vontade para contribuir ou abrir uma issue no repositório. 

👉 **[Clique aqui para baixar o jogo](https://www.dropbox.com/scl/fi/68s3et88llcmjg0of7zlf/Punch-Quest.rar?rlkey=1a7ujqvuc8c6onpb8yuua2hrw&e=1&st=g71c3ey3&dl=0)** 
👉**[Clique aqui para ver o vídeo do jogo](https://www.youtube.com/watch?v=mkEHUfyXcak)** 
👉**[Clique aqui para ver o segundo vídeo do jogo](https://youtu.be/paCLy_-e5CU)** 

