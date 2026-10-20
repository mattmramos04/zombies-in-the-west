extends Node2D
## Stationary gunslinger: targets the closest living zombie within range.

const Visual = preload("res://scripts/actor_visual.gd")
const TEXTURE = preload("res://assets/defender.png")
var game: Node2D
var health: float = 100.0
var maximum_health: float = 100.0
var cooldown: float = 0.4
var dead: bool = false
var visual: Node2D
var shot_to := Vector2.ZERO
var shot_flash: float = 0.0

func setup(controller: Node2D, location: Vector2) -> void:
	game = controller
	position = location
	visual = Visual.new()
	add_child(visual)
	visual.setup(TEXTURE)
	visual.bar_color = Color("eeb266")

func _physics_process(delta: float) -> void:
	if dead or game.finished:
		return
	shot_flash = maxf(0.0, shot_flash - delta)
	cooldown -= delta
	if cooldown <= 0.0:
		var target: Node2D = game.zombie_in_reach(position, 145.0)
		if target != null:
			shot_to = target.position - position
			shot_flash = 0.1
			target.take_damage(9.0)
			cooldown = 0.8
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 23, Color("694c39"))
	if shot_flash > 0.0:
		draw_line(Vector2.ZERO, shot_to, Color("ffe7a0"), 2)

func take_damage(amount: float) -> void:
	if dead:
		return
	health = maxf(0.0, health - amount)
	visual.show_health(health, maximum_health)
	if health <= 0.0:
		dead = true
		game.defense_destroyed()
		queue_free()
