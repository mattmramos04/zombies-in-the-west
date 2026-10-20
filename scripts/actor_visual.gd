extends Node2D
## Five 32x32 frames: four on row one, one on row two.

var animation: AnimatedSprite2D
var is_heavy: bool = false
var health_ratio: float = 1.0
var bar_color := Color("9bdb64")

func setup(texture: Texture2D, heavy: bool = false) -> void:
	is_heavy = heavy
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	animation = AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 7.0)
	for index in range(5):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2((index % 4) * 32, (index / 4) * 32, 32, 32)
		frames.add_frame("default", atlas)
	animation.sprite_frames = frames
	animation.scale = Vector2(2.5, 2.5) if heavy else Vector2(2, 2)
	add_child(animation)
	animation.play()

func _draw() -> void:
	if is_heavy:
		draw_arc(Vector2.ZERO, 19.0, 0.0, TAU, 24, Color("9faaff"), 3.0)
	draw_rect(Rect2(-18, -25, 36, 4), Color("352d28"))
	draw_rect(Rect2(-18, -25, 36 * health_ratio, 4), bar_color)

func show_health(current: float, maximum: float) -> void:
	health_ratio = clampf(current / maximum, 0.0, 1.0)
	queue_redraw()
