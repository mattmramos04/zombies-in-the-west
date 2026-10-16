extends SceneTree
## Run with: godot --headless --path . --fixed-fps 60 --script tests/smoke_test.gd

const GameScene = preload("res://scenes/main.tscn")
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func make_game() -> Node2D:
	var game := GameScene.instantiate()
	root.add_child(game)
	return game

func _run() -> void:
	var game := make_game()
	await process_frame
	check(game.defenses.get_child_count() == 4, "Four starting defenses")
	check(game.spawn_zombie(), "Initial deployment succeeds")
	check(is_equal_approx(game.supply, 120.0), "Walker deducts 20 supply")
	check(not game.spawn_zombie(), "Deployment cooldown enforced")
	game.toggle_pause()
	var before: float = game.elapsed
	await physics_frame
	await physics_frame
	check(is_equal_approx(game.elapsed, before), "Pause freezes simulation")
	check(not game.spawn_zombie(), "Pause prevents deployment")
	game.toggle_pause()
	game.spawn_cooldown = 0.0
	game.supply = 0.0
	check(not game.spawn_zombie(), "Insufficient supply blocks deployment")
	game.supply = 140.0
	game.select_route(1)
	game.select_kind("brute")
	check(game.spawn_zombie(), "Brute deploys on south route")
	var brute = game.zombies.get_child(1)
	check(brute.route[0] == game.routes[1][0], "Selected route reaches unit")
	check(brute.maximum_health == 180.0, "Brute uses heavy stats")
	var defender = game.defenses.get_child(0)
	var supply_before: float = game.supply
	defender.take_damage(1000.0)
	defender.take_damage(1000.0)
	check(is_equal_approx(game.supply, supply_before + 25.0), "Defense reward awarded exactly once")
	game.queue_free()
	await process_frame
	game = make_game()
	await process_frame
	# Exercise real movement, combat, targeting, deaths, income, and victory.
	var ticks: int = 0
	while not game.finished and ticks < 6200:
		if game.supply >= 50.0:
			game.select_kind("brute")
		else:
			game.select_kind("walker")
		game.spawn_zombie()
		ticks += 1
		await physics_frame
	print("Autoplay: town HP=", game.town_health, " time=", game.elapsed, " living units=", game.zombies.get_child_count())
	check(game.finished and game.town_health <= 0.0, "Concentrated north-route horde can win")
	check(not game.spawn_zombie(), "Finished match prevents deployment")
	game.queue_free()
	await process_frame
	game = make_game()
	await process_frame
	game.elapsed = game.TIME_LIMIT - 0.01
	await physics_frame
	await physics_frame
	check(game.finished and game.town_health > 0.0, "Idle round loses at time limit")
	game.queue_free()
	await process_frame
	print("Smoke tests: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
