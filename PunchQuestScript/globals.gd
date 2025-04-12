extends Node

const MAX_LIFE := 25
const MAX_LIVES := 3

var life: int = MAX_LIFE
var current_lives: int = MAX_LIVES
var checkpoint_position: Vector2 = Vector2.ZERO
var has_checkpoint: bool = false
var respawn_on_checkpoint := false
var player: Node = null
var last_scene: String = "res://levels/world.tscn"
var initial_position_spawn: Vector2 = Vector2.ZERO

func set_life(value: int) -> void:
	life = clamp(value, 0, MAX_LIFE)

func lose_life() -> bool:
	current_lives -= 1
	return current_lives > 0

func reset_var(reset_life := true, reset_lives := false, reset_checkpoint := true) -> void:
	if reset_life:
		life = MAX_LIFE
	if reset_lives:
		current_lives = MAX_LIVES
	if reset_checkpoint:
		checkpoint_position = Vector2.ZERO
		has_checkpoint = false
		respawn_on_checkpoint = false

func reset_game() -> void:
	reset_var(true, true, true)

func respawn_player():
	if player:
		player.queue_free()
	await get_tree().process_frame

	var world_scene = load(last_scene).instantiate()
	get_tree().current_scene.free()
	get_tree().root.add_child(world_scene)
	get_tree().current_scene = world_scene
