extends StaticBody2D

@export var max_health: int = 10
var current_health: int = 0

@onready var sprite: Sprite2D = $Sprite2D # Or ColorRect if using shapes

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int) -> void:
	current_health -= amount
	
	# Optional: Flash red to indicate taking damage
	if sprite:
		sprite.modulate = Color(1, 0, 0)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(sprite):
			sprite.modulate = Color(1, 1, 1)
			
	if current_health <= 0:
		die()

func die() -> void:
	# Play death animation or particle effect here before freeing
	queue_free()
