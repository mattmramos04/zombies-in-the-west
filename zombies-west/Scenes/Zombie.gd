extends CharacterBody2D

@export var move_speed: float = 75.0
@export var attack_damage: int = 15
@export var attack_cooldown: float = 2.5

var current_target: Node2D = null
var attack_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if current_target and is_instance_valid(current_target):
		# We are in melee range of a target, stop moving and attack
		velocity = Vector2.ZERO
		attack_timer += delta
		
		if attack_timer >= attack_cooldown:
			if current_target.has_method("take_damage"):
				current_target.take_damage(attack_damage)
			attack_timer = 0.0
	else:
		# Not in attack range, find the nearest global defender to walk towards
		current_target = null
		attack_timer = 0.0
		
		var nearest_defender = get_nearest_defender()
		if nearest_defender:
			# Get the normalized directional vector pointing at the closest target
			var direction = global_position.direction_to(nearest_defender.global_position)
			velocity = direction * move_speed
		else:
			# If all defenders on the map are dead, stop moving (or set to Vector2.RIGHT to march off screen)
			velocity = Vector2.ZERO
			
	move_and_slide()

# Iterates through all active defenders to find the closest one geometrically
func get_nearest_defender() -> Node2D:
	var defenders = get_tree().get_nodes_in_group("defender")
	if defenders.is_empty():
		return null
		
	var nearest: Node2D = null
	var min_dist: float = INF
	
	for defender in defenders:
		# distance_squared_to is computationally cheaper than distance_to because it avoids a square root calculation
		var dist = global_position.distance_squared_to(defender.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = defender
			
	return nearest

# These Area2D signals still determine when the zombie has successfully reached the target to begin attacking
func _on_aggro_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("defender") and current_target == null:
		current_target = body

func _on_aggro_range_body_exited(body: Node2D) -> void:
	if body == current_target:
		current_target = null
