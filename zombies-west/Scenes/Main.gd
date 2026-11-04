extends Node2D

@export var zombie_scene: PackedScene
@export var starting_currency: int = 80
@export var currency_regen_rate: int = 3
@export var zombie_cost: int = 15

var current_currency: int = 0
var drop_zone: Rect2 = Rect2(0, 0, 250, 720) # A 250px wide spawn area on the left
var time_passed: float = 0.0

func _ready() -> void:
	current_currency = starting_currency

func _process(delta: float) -> void:
	# Passively regenerate currency over time
	time_passed += delta
	if time_passed >= 1.0:
		current_currency += currency_regen_rate
		time_passed = 0.0
		# In a full game, you would update your UI label here:
		# $CanvasLayer/CurrencyLabel.text = "Infection: " + str(current_currency)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if drop_zone.has_point(event.position):
			_attempt_spawn(event.position)

func _attempt_spawn(spawn_pos: Vector2) -> void:
	if current_currency >= zombie_cost:
		current_currency -= zombie_cost
		
		var zombie = zombie_scene.instantiate()
		zombie.global_position = spawn_pos
		add_child(zombie)
	else:
		print("Not enough currency!")
