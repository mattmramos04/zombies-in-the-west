extends Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func _on_resume_pressed() -> void:
	get_tree().paused = false
	hide()

func _on_quit_to_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			get_tree().paused = false
			hide()
		else:
			show()
			get_tree().paused = true

		get_viewport().set_input_as_handled()
