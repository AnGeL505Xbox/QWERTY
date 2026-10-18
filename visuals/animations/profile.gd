extends Resource

@export var texture: Texture2D
@export var frames: SpriteFrames
@export var tint := Color.WHITE
@export var pixel_size := 0.012
@export var facing := 1.0
@export var animation_names: Dictionary = {}
@export var durations: Dictionary = {
	"enter": 0.35, "attack": 0.32, "defend": 0.35, "hurt": 0.28,
	"special": 0.55, "crisis": 0.45, "victory": 0.5, "defeat": 0.5
}
