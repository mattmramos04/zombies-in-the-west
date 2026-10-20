extends Node2D
## One-settlement checkpoint. All coordinates are in a 1280x720 viewport.

const Zombie = preload("res://scripts/zombie.gd")
const Defender = preload("res://scripts/defender.gd")
const STARTING_SUPPLY: float = 140.0
const SUPPLY_PER_SECOND: float = 7.0
const MAX_SUPPLY: float = 250.0
const TIME_LIMIT: float = 100.0
const TOWN_MAX_HEALTH: float = 360.0
const SPAWN_INTERVAL: float = 0.3
const UNIT_CAP: int = 50

var routes: Array[PackedVector2Array] = [
	PackedVector2Array([Vector2(120, 250), Vector2(480, 250), Vector2(650, 350), Vector2(1030, 350)]),
	PackedVector2Array([Vector2(120, 490), Vector2(480, 490), Vector2(650, 390), Vector2(1030, 390)]),
]
var supply: float = STARTING_SUPPLY
var town_health: float = TOWN_MAX_HEALTH
var elapsed: float = 0.0
var spawn_cooldown: float = 0.0
var finished: bool = false
var selected_kind: String = "walker"
var selected_route: int = 0
var zombies: Node2D
var defenses: Node2D
var status_label: Label
var hint_label: Label
var result_panel: PanelContainer
var result_label: Label
var walker_button: Button
var brute_button: Button
var upper_button: Button
var lower_button: Button
var spawn_button: Button
var pause_button: Button
var town_bar: ProgressBar

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	zombies = Node2D.new()
	zombies.name = "Zombies"
	zombies.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(zombies)
	defenses = Node2D.new()
	defenses.name = "Defenses"
	defenses.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(defenses)
	for location in [Vector2(440, 195), Vector2(440, 545), Vector2(810, 315), Vector2(810, 425)]:
		var defender := Defender.new()
		defender.setup(self, location)
		defenses.add_child(defender)
	_build_ui()
	_update_ui()

func _physics_process(delta: float) -> void:
	if finished or get_tree().paused:
		return
	elapsed += delta
	supply = minf(MAX_SUPPLY, supply + SUPPLY_PER_SECOND * delta)
	spawn_cooldown = maxf(0.0, spawn_cooldown - delta)
	if elapsed >= TIME_LIMIT:
		finish(false)
	_update_ui()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1: select_kind("walker")
		KEY_2: select_kind("brute")
		KEY_Q: select_route(0)
		KEY_E: select_route(1)
		KEY_SPACE: spawn_zombie()
		KEY_P: toggle_pause()
		KEY_R: restart()

func select_kind(kind: String) -> void:
	selected_kind = kind
	_update_ui()

func select_route(index: int) -> void:
	selected_route = index
	queue_redraw()
	_update_ui()

func spawn_zombie() -> bool:
	if finished or get_tree().paused or spawn_cooldown > 0.0:
		return false
	var cost: int = Zombie.STATS[selected_kind].cost
	if supply < cost or zombies.get_child_count() >= UNIT_CAP:
		return false
	supply -= cost
	spawn_cooldown = SPAWN_INTERVAL
	var zombie := Zombie.new()
	zombie.setup(self, routes[selected_route], selected_kind)
	zombies.add_child(zombie)
	_update_ui()
	return true

func zombie_in_reach(location: Vector2, radius: float) -> Node2D:
	return _closest(zombies, location, radius)

func defense_in_reach(location: Vector2, radius: float) -> Node2D:
	return _closest(defenses, location, radius)

func _closest(container: Node2D, location: Vector2, radius: float) -> Node2D:
	var closest: Node2D = null
	var distance: float = radius
	for actor in container.get_children():
		if actor.dead:
			continue
		var candidate: float = actor.position.distance_to(location)
		if candidate <= distance:
			distance = candidate
			closest = actor
	return closest

func damage_town(amount: float) -> void:
	if finished:
		return
	town_health = maxf(0.0, town_health - amount)
	if town_health <= 0.0:
		finish(true)
	_update_ui()

func defense_destroyed() -> void:
	# Temporary economy: passive income + a reward for destroying defenses.
	supply = minf(MAX_SUPPLY, supply + 25.0)

func finish(won: bool) -> void:
	finished = true
	result_label.text = "SETTLEMENT OVERRUN!" if won else "THE TOWN HELD OUT"
	result_label.text += "\nYour horde wins." if won else "\nTime ran out. Try concentrating your horde on one route."
	result_panel.show()
	_update_ui()

func toggle_pause() -> void:
	if finished:
		return
	get_tree().paused = not get_tree().paused
	_update_ui()

func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _button(text: String, callback: Callable, parent: Node) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 42)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var top := PanelContainer.new()
	top.position = Vector2(20, 16)
	top.size = Vector2(1240, 90)
	canvas.add_child(top)
	var top_box := VBoxContainer.new()
	top.add_child(top_box)
	var title := Label.new()
	title.text = "  ZOMBIES IN THE WEST  /  CHECKPOINT 01"
	title.add_theme_font_size_override("font_size", 24)
	top_box.add_child(title)
	status_label = Label.new()
	top_box.add_child(status_label)
	town_bar = ProgressBar.new()
	town_bar.max_value = TOWN_MAX_HEALTH
	town_bar.custom_minimum_size.y = 12
	town_bar.show_percentage = false
	top_box.add_child(town_bar)
	var bottom := PanelContainer.new()
	bottom.position = Vector2(20, 610)
	bottom.size = Vector2(1240, 96)
	canvas.add_child(bottom)
	var box := VBoxContainer.new()
	bottom.add_child(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	walker_button = _button("1  Walker / 20", select_kind.bind("walker"), row)
	brute_button = _button("2  Brute / 50", select_kind.bind("brute"), row)
	upper_button = _button("Q  North route", select_route.bind(0), row)
	lower_button = _button("E  South route", select_route.bind(1), row)
	spawn_button = _button("SPACE  Deploy zombie", spawn_zombie, row)
	pause_button = _button("P  Pause", toggle_pause, row)
	_button("R  Restart", restart, row)
	hint_label = Label.new()
	box.add_child(hint_label)
	result_panel = PanelContainer.new()
	result_panel.position = Vector2(330, 260)
	result_panel.size = Vector2(620, 170)
	canvas.add_child(result_panel)
	var result_box := VBoxContainer.new()
	result_panel.add_child(result_box)
	result_label = Label.new()
	result_label.custom_minimum_size = Vector2(600, 100)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 22)
	result_box.add_child(result_label)
	_button("Play again", restart, result_box)
	result_panel.hide()

func _update_ui() -> void:
	if status_label == null:
		return
	status_label.text = "  Supply: %d / %d (+7/sec)     Town: %d / %d HP     Time: %ds     Horde: %d / %d" % [int(supply), int(MAX_SUPPLY), int(town_health), int(TOWN_MAX_HEALTH), maxi(0, ceili(TIME_LIMIT - elapsed)), zombies.get_child_count(), UNIT_CAP]
	town_bar.value = town_health
	walker_button.text = ("> " if selected_kind == "walker" else "") + "1  Walker / 20"
	brute_button.text = ("> " if selected_kind == "brute" else "") + "2  Brute / 50"
	upper_button.text = ("> " if selected_route == 0 else "") + "Q  North"
	lower_button.text = ("> " if selected_route == 1 else "") + "E  South"
	spawn_button.disabled = finished or get_tree().paused or spawn_cooldown > 0.0 or supply < Zombie.STATS[selected_kind].cost or zombies.get_child_count() >= UNIT_CAP
	pause_button.text = "P  Resume" if get_tree().paused else "P  Pause"
	hint_label.text = "  Destroy the town before time runs out. Defenses award 25 supply. Select a unit and route, then deploy."
	if get_tree().paused:
		hint_label.text = "  PAUSED - press P or Resume to continue."

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("b58b58"))
	# Placeholder settlement and desert scenery; no external asset dependency.
	for point in [Vector2(240, 385), Vector2(610, 170), Vector2(930, 540), Vector2(160, 160)]:
		draw_line(point, point + Vector2(0, -26), Color("516442"), 7)
		draw_line(point + Vector2(-12, -10), point + Vector2(10, -10), Color("516442"), 5)
	for index in range(routes.size()):
		draw_polyline(routes[index], Color("775b40"), 52, true)
		draw_polyline(routes[index], Color("d3b17c"), 40, true)
		draw_circle(routes[index][0], 29, Color("426447") if selected_route == index else Color("7a7852"))
		draw_string(ThemeDB.fallback_font, routes[index][0] + Vector2(-38, -45), "NORTH" if index == 0 else "SOUTH", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("292c25"))
	for building in [Rect2(660, 130, 110, 75), Rect2(930, 150, 130, 75), Rect2(660, 510, 110, 75), Rect2(980, 505, 120, 75)]:
		draw_rect(building, Color("77513c"))
		draw_rect(Rect2(building.position + Vector2(-5, -7), Vector2(building.size.x + 10, 14)), Color("563c31"))
		draw_rect(Rect2(building.position + Vector2(40, 35), Vector2(22, 40)), Color("3c302b"))
	draw_rect(Rect2(1050, 285, 160, 170), Color("6e4835"))
	draw_rect(Rect2(1040, 275, 180, 30), Color("42352e"))
	draw_string(ThemeDB.fallback_font, Vector2(1080, 298), "TOWN HALL", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ffdda0"))
	draw_rect(Rect2(1110, 385, 40, 70), Color("302c28"))
	draw_string(ThemeDB.fallback_font, Vector2(28, 580), "GREEN: YOUR HORDE     BROWN: TOWN DEFENSES     BLUE: BRUTES", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("2d3026"))
