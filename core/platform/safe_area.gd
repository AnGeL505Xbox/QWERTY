extends MarginContainer

var base_margins := Vector4.ZERO

static func insets(physical_size: Vector2, safe_rect: Rect2, logical_size: Vector2) -> Vector4:
	if physical_size.x <= 0 or physical_size.y <= 0 or not safe_rect.has_area(): return Vector4.ZERO
	var bounded := safe_rect.intersection(Rect2(Vector2.ZERO, physical_size))
	if not bounded.has_area(): return Vector4.ZERO
	var ratio := logical_size / physical_size
	return Vector4(bounded.position.x * ratio.x, bounded.position.y * ratio.y, (physical_size.x - bounded.end.x) * ratio.x, (physical_size.y - bounded.end.y) * ratio.y)

func _ready() -> void:
	base_margins = Vector4(get_theme_constant("margin_left"), get_theme_constant("margin_top"), get_theme_constant("margin_right"), get_theme_constant("margin_bottom"))
	get_viewport().size_changed.connect(refresh)
	refresh()

func refresh() -> void:
	var extra := Vector4.ZERO
	if OS.has_feature("android") or OS.has_feature("ios"):
		var safe := Rect2(DisplayServer.get_display_safe_area())
		safe.position -= Vector2(DisplayServer.window_get_position())
		extra = insets(Vector2(DisplayServer.window_get_size()), safe, get_viewport_rect().size)
	apply_insets(extra)

func apply_insets(extra: Vector4) -> void:
	var edges := ["left", "top", "right", "bottom"]
	for index in range(4): add_theme_constant_override("margin_" + edges[index], int(ceil(base_margins[index] + extra[index])))
