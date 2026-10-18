@tool
class_name RpgVisualProfile
extends Resource

@export var texture: Texture2D:
	set(value):
		texture = value
		emit_changed()
@export var frames: SpriteFrames:
	set(value):
		if frames != null and frames.changed.is_connected(_on_frames_changed):
			frames.changed.disconnect(_on_frames_changed)
		frames = value
		if frames != null:
			frames.changed.connect(_on_frames_changed)
		emit_changed()
@export var tint := Color.WHITE:
	set(value):
		tint = value
		emit_changed()
@export var pixel_size := 0.012:
	set(value):
		pixel_size = value
		emit_changed()
@export var facing := 1.0
@export var animation_names: Dictionary = {}
@export var durations: Dictionary = {
	"enter": 0.35, "attack": 0.32, "defend": 0.35, "hurt": 0.28,
	"special": 0.55, "crisis": 0.45, "victory": 0.5, "defeat": 0.5
}

func _on_frames_changed() -> void:
	emit_changed()
