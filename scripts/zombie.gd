extends Node2D
## A unit follows a selected route and stops to attack reachable defenses.

const Visual = preload("res://scripts/actor_visual.gd")
const TEXTURE = preload("res://assets/zombie.png")
const STATS = {
	"walker": {"cost": 20, "health": 65.0, "speed": 56.0, "damage": 14.0},
	"brute": {"cost": 50, "health": 180.0, "speed": 37.0, "damage": 26.0},
}
var game: Node2D
var route: PackedVector2Array
var waypoint: int = 1
var health: float
var maximum_health: float
var speed: float
var damage: float
var cooldown: float = 0.0
var dead: bool = false
var visual: Node2D

func setup(controller: Node2D, points: PackedVector2Array, kind: String) -> void:
	game = controller
	route = points
	position = route[0]
	var stats: Dictionary = STATS[kind]
	health = stats.health
	maximum_health = health
	speed = stats.speed
	damage = stats.damage
	visual = Visual.new()
	add_child(visual)
	visual.setup(TEXTURE, kind == "brute")

func _physics_process(delta: float) -> void:
	if dead or game.finished:
		return
	cooldown = maxf(0.0, cooldown - delta)
	var target: Node2D = game.defense_in_reach(position, 88.0)
	if target != null:
		visual.animation.pause()
		if cooldown <= 0.0:
			target.take_damage(damage)
			cooldown = 0.8
		return
	if waypoint >= route.size():
		visual.animation.pause()
		if cooldown <= 0.0:
			game.damage_town(damage)
			cooldown = 0.8
		return
	visual.animation.play()
	position = position.move_toward(route[waypoint], speed * delta)
	if position.distance_to(route[waypoint]) < 0.1:
		waypoint += 1

func take_damage(amount: float) -> void:
	if dead:
		return
	health = maxf(0.0, health - amount)
	visual.show_health(health, maximum_health)
	if health <= 0.0:
		dead = true
		queue_free()
