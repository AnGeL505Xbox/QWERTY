extends Node

signal changed
const QUALITIES = ["ahorro", "equilibrado", "alto"]
@export var path := "user://preferences.cfg"
var quality := "equilibrado"
var fps := 60
var reduced_motion := false
var effects := true
var fullscreen := false
var notice := ""

static func normalized(values: Dictionary, mobile: bool = false) -> Dictionary:
	var defaults := {"quality": "ahorro" if mobile else "equilibrado", "fps": 30 if mobile else 60, "reduced_motion": false, "effects": true, "fullscreen": false}
	for key in defaults:
		var value = values.get(key)
		if key == "quality" and value in QUALITIES: defaults[key] = value
		elif key == "fps" and (value is int or value is float) and value in [30, 60]: defaults[key] = int(value)
		elif key in ["reduced_motion", "effects", "fullscreen"] and value is bool: defaults[key] = value
	return defaults

func _ready() -> void:
	load_preferences()

func values() -> Dictionary:
	return {"quality": quality, "fps": fps, "reduced_motion": reduced_motion, "effects": effects, "fullscreen": fullscreen}

func load_preferences() -> void:
	var config := ConfigFile.new()
	var error := config.load(path)
	var stored: Dictionary = {}
	notice = ""
	if error == OK:
		for key in values(): stored[key] = config.get_value("display", key, null)
	elif error != ERR_FILE_NOT_FOUND:
		notice = "No se pudieron leer los ajustes. Se usan valores predeterminados; el archivo se conserva."
	_assign(normalized(stored, OS.has_feature("android")))

func update_preferences(proposal: Dictionary) -> void:
	_assign(normalized(proposal, OS.has_feature("android")))
	var config := ConfigFile.new()
	for key in values(): config.set_value("display", key, values()[key])
	# No tocar la expedición: los ajustes se guardan por separado.
	var error := config.save(path)
	notice = "Ajustes guardados." if error == OK else "Ajustes aplicados; no se pudieron guardar en este dispositivo."
	changed.emit()

func _assign(proposal: Dictionary) -> void:
	for key in proposal: set(key, proposal[key])

func apply_to(viewport: Viewport, arena: Node) -> void:
	Engine.max_fps = fps
	viewport.scaling_3d_scale = {"ahorro": 0.65, "equilibrado": 0.85, "alto": 1.0}[quality]
	viewport.msaa_3d = Viewport.MSAA_2X if quality == "alto" else Viewport.MSAA_DISABLED
	# Las preferencias son multiplicadores de las opciones visuales de la escena.
	arena.presentation_motion = not reduced_motion
	arena.feedback.presentation_enabled = effects
	if not OS.has_feature("android") and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
