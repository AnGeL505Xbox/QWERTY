@tool
extends RefCounted

static func wrap(window: AcceptDialog, content: Control) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = "ScrollableContent"
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	window.add_child(scroll)
	scroll.add_child(content)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	window.unresizable = false
	return scroll

static func fitted_size(preferred: Vector2i, available: Vector2i) -> Vector2i:
	return Vector2i(maxi(1, mini(preferred.x, int(available.x * 0.90))), maxi(1, mini(preferred.y, int(available.y * 0.84))))

static func open(window: Window, preferred := Vector2i(1000, 700)) -> void:
	var available := DisplayServer.screen_get_usable_rect(window.current_screen).size
	if window.is_embedded() or available.x <= 0 or available.y <= 0:
		available = Vector2i(window.get_parent().get_viewport().get_visible_rect().size)
	window.popup_centered(fitted_size(preferred, available))
