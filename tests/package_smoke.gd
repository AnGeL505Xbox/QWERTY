extends SceneTree

# Ejecutar desde disco con --main-pack; esta prueba queda excluida del paquete.
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		push_error(message)
		failures += 1
func _initialize() -> void: call_deferred("run")
func run() -> void:
	check(not FileAccess.file_exists("res://tests/run.gd"), "Paquete excluye pruebas")
	check(not FileAccess.file_exists("res://addons/content_editor/plugin.gd"), "Paquete excluye plugin de desarrollo")
	check(not FileAccess.file_exists("res://tools/editor/editing.gd"), "Paquete excluye herramientas")
	var main = load("res://scenes/main.tscn").instantiate()
	main.save_path = "user://test_package_smoke.json"
	main.get_node("Preferences").path = "user://test_package_smoke.cfg"
	root.add_child(main)
	await process_frame
	check(main.ui.get_node("%Menu").visible, "Menú arranca desde paquete")
	main._start()
	check(main.battle != null and main.battle.team.size() == 2, "Combate carga catálogo y scripts empaquetados")
	main._open_settings()
	check(main.settings.visible, "Ajustes cargan escena empaquetada")
	main._close_settings()
	main._menu()
	main._new_expedition("42")
	check(main.run != null and main.run.nodes.size() == 9, "Expedición funciona desde paquete")
	main.queue_free()
	await process_frame
	for suffix in [".json", ".json.bak", ".json.tmp", ".cfg"]: DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_package_smoke" + suffix))
	print("PAQUETE: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)
