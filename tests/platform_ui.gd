extends SceneTree

const Preferences = preload("res://core/platform/preferences.gd")
const SafeArea = preload("res://core/platform/safe_area.gd")
const DialogLayout = preload("res://tools/editor/dialog_layout.gd")
const Store = preload("res://core/save_system/store.gd")
const PATH = "user://test_platform_ui"
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		push_error(message)
		failures += 1
func _initialize() -> void: call_deferred("run")
func key(main: Node, code: int, echo_value: bool = false, ctrl: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	event.echo = echo_value
	event.ctrl_pressed = ctrl
	main._unhandled_key_input(event)
func frames() -> void:
	await process_frame
	await process_frame
func run() -> void:
	var fps_before := Engine.max_fps
	check(Preferences.normalized({}, true).quality == "ahorro" and Preferences.normalized({}, true).fps == 30, "Predeterminados Android conservadores")
	check(Preferences.normalized({}).quality == "equilibrado", "Predeterminados PC")
	var normalized := Preferences.normalized({"quality": "desconocido", "fps": -1, "effects": "sí", "fullscreen": true})
	check(normalized.quality == "equilibrado" and normalized.fps == 60 and normalized.effects == true and normalized.fullscreen == true, "Normalizar valores inválidos sin perder valores válidos")
	check(DialogLayout.fitted_size(Vector2i(1000, 700), Vector2i(800, 480)) == Vector2i(720, 403), "Ventana deja espacio al borde y barra de título")
	check(DialogLayout.fitted_size(Vector2i(540, 400), Vector2i(1920, 1080)) == Vector2i(540, 400), "Ventana pequeña mantiene tamaño solicitado")
	check(SafeArea.insets(Vector2(2400, 1080), Rect2(100, 40, 2200, 1000), Vector2(1600, 720)).is_equal_approx(Vector4(200.0 / 3, 80.0 / 3, 200.0 / 3, 80.0 / 3)), "Zonas seguras físicas se convierten a unidades UI")
	check(SafeArea.insets(Vector2(1280, 720), Rect2(-20, -20, 1400, 800), Vector2(1280, 720)) == Vector4.ZERO, "Zona segura limitada a la ventana")
	check(SafeArea.insets(Vector2.ZERO, Rect2(), Vector2(1280, 720)) == Vector4.ZERO, "Pantalla no disponible no añade márgenes")
	var broken := FileAccess.open(PATH + ".cfg", FileAccess.WRITE)
	broken.store_string("[ajustes sin cerrar")
	broken.close()
	var pref := Preferences.new()
	pref.path = PATH + ".cfg"
	print("Prueba de recuperación: se espera un diagnóstico de ConfigFile por archivo malformado.")
	root.add_child(pref)
	check(pref.quality == "equilibrado" and pref.notice != "", "Archivo de ajustes inválido recupera valores predeterminados")
	check(FileAccess.get_file_as_string(pref.path) == "[ajustes sin cerrar", "Carga inválida conserva el archivo original")
	pref.update_preferences({"quality": "ahorro", "fps": 30, "effects": false, "reduced_motion": true, "fullscreen": false})
	var restored := Preferences.new()
	restored.path = pref.path
	root.add_child(restored)
	check(restored.values() == pref.values(), "Ajustes aplicados sobreviven una recarga")
	pref.queue_free()
	restored.queue_free()
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(640, 360)
	var main = load("res://scenes/main.tscn").instantiate()
	main.save_path = PATH + ".json"
	main.get_node("Preferences").path = PATH + ".cfg"
	main.get_node("Interface/Scroll/Margin").add_theme_constant_override("margin_left", 42)
	root.add_child(main)
	await frames()
	check(main.get_node("Settings").visible == false, "Ajustes cerrados al arrancar")
	check(main.preferences.fps == 30 and Engine.max_fps == 30, "Preferencias cargadas se aplican al motor")
	check(not main.arena.presentation_motion and not main.arena.feedback.presentation_enabled, "Ahorro visual aplicado sin cambiar reglas")
	var scroll: ScrollContainer = main.ui.get_node("Scroll")
	check(scroll.size.y <= 360 and scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page, "Menú largo usa desplazamiento en 640×360")
	check(scroll.get_h_scroll_bar().max_value <= scroll.get_h_scroll_bar().page + 1, "Menú sin desbordamiento horizontal")
	main.ui.get_node("%Exit").grab_focus()
	await frames()
	check(scroll.scroll_vertical > 0, "Foco desplaza menú para alcanzar botones inferiores")
	var margin = main.ui.get_node("Scroll/Margin")
	margin.apply_insets(Vector4(20, 10, 30, 0))
	check(margin.get_theme_constant("margin_left") == 62, "Zona segura suma al margen editado")
	margin.apply_insets(Vector4(20, 10, 30, 0))
	check(margin.get_theme_constant("margin_left") == 62, "Recalcular zona segura no acumula márgenes")
	margin.apply_insets(Vector4.ZERO)
	check(margin.get_theme_constant("margin_left") == 42, "Restaurar zona segura respeta escena editada")
	main._choose_enemy(0)
	main.battle.hand = ["corte"]
	main._render()
	key(main, KEY_1)
	check(main.selected == 0, "Número selecciona carta jugable")
	var target: Button = main.ui.get_node("%Targets").get_child(0)
	check(target.has_focus(), "Selección por teclado enfoca objetivo")
	var health: int = main.battle.enemy_health
	target.pressed.emit()
	check(main.battle.enemy_health < health and main.selected == -1, "Confirmación enfocada usa reglas del combate")
	var turn: int = main.battle.turn
	key(main, KEY_E, true)
	key(main, KEY_E, false, true)
	check(main.battle.turn == turn, "Repetición y Ctrl no ejecutan turno")
	key(main, KEY_E)
	check(main.battle.turn == turn + 1, "E termina turno")
	main.battle.hand = ["corte"]
	main._render()
	key(main, KEY_9)
	check(main.selected == -1, "Número fuera de mano no selecciona")
	key(main, KEY_1)
	key(main, KEY_ESCAPE)
	check(main.selected == -1 and main.ui.get_node("%Battle").visible, "Escape cancela sin abandonar combate")
	key(main, KEY_F10)
	check(main.settings.visible and not main.ui.visible, "F10 abre ajustes y oculta controles de juego")
	turn = main.battle.turn
	key(main, KEY_E)
	check(main.battle.turn == turn, "Ajustes bloquean atajos del combate")
	main.settings.get_node("%Quality").select(2)
	main.settings.get_node("%FPS").select(1)
	main.settings.get_node("%Motion").button_pressed = false
	main.settings.get_node("%Effects").button_pressed = true
	main.arena.motion_enabled = false
	main.arena.feedback.enabled = false
	main.settings.get_node("%Apply").pressed.emit()
	check(main.preferences.quality == "alto" and Engine.max_fps == 60, "Botón aplica calidad y FPS")
	check(is_equal_approx(root.scaling_3d_scale, 1.0) and root.msaa_3d == Viewport.MSAA_2X, "Perfil alto configura resolución y antialiasing")
	check(main.arena.motion_enabled == false and main.arena.feedback.enabled == false, "Preferencias respetan opciones editadas en escena")
	check(main.arena.presentation_motion and main.arena.feedback.presentation_enabled, "Preferencias actúan como multiplicadores")
	main._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not main.settings.visible and main.ui.visible, "Atrás cierra ajustes y recupera pantalla")
	main._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(main.ui.get_node("%Menu").visible, "Atrás vuelve al menú de entrenamiento")
	main._new_expedition("42")
	var snapshot: Dictionary = main.run.export_state()
	main.run_ui.get_node("%Settings").pressed.emit()
	check(main.settings.visible and not main.run_ui.visible, "Ajustes accesibles desde expedición")
	main.settings.get_node("%Back").pressed.emit()
	check(main.run_ui.visible and main.run.export_state() == snapshot, "Cerrar ajustes conserva expedición")
	main._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(Store.read(main.save_path).has("state"), "Pausa de aplicación guarda expedición")
	check(main.run.export_state() == snapshot, "Autoguardado en pausa no muta partida")
	main._open_settings()
	main.settings.get_node("%Quality").select(0)
	main._close_settings()
	check(main.preferences.quality == "alto", "Cerrar sin aplicar descarta cambios de ajustes")
	main.queue_free()
	await frames()
	for suffix in [".cfg", ".json", ".json.bak", ".json.tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	Engine.max_fps = fps_before
	print("PLATAFORMA/UI: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)
