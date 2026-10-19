extends SceneTree

const Store = preload("res://core/save_system/store.gd")
const Autoplay = preload("res://tests/support/autoplay.gd")
const PATH = "user://test_roguelike_scene.json"
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		push_error(message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func canonical(value):
	return JSON.parse_string(JSON.stringify(value))

func run() -> void:
	for path in [PATH, PATH + ".bak", PATH + ".tmp", PATH + ".tscn"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var main = load("res://scenes/main.tscn").instantiate()
	main.save_path = PATH
	root.add_child(main)
	await process_frame
	var menu := "Margin/Menu/Expedition/"
	main.ui.get_node(menu + "Seed").text = "invalida"
	main.ui.get_node(menu + "RunActions/NewRun").pressed.emit()
	check(main.run == null and not FileAccess.file_exists(PATH), "Semilla inválida no reemplaza guardado")
	main.ui.get_node(menu + "Seed").text = "42"
	main.ui.get_node(menu + "RunActions/NewRun").pressed.emit()
	await process_frame
	check(main.run != null and main.run.phase == "map" and main.run_ui.visible, "Nueva expedición desde botón")
	check(Store.read(PATH).has("state"), "Guardado inicial desde interfaz")
	main.run_ui.get_node("Margin/Layout/MapScroll/Route").step = Vector2(190, 120)
	var editable_scene := PackedScene.new()
	check(editable_scene.pack(main.run_ui) == OK and ResourceSaver.save(editable_scene, PATH + ".tscn") == OK, "Guardar diseño de mapa editado")
	var restored_ui = ResourceLoader.load(PATH + ".tscn", "", ResourceLoader.CACHE_MODE_IGNORE_DEEP).instantiate()
	root.add_child(restored_ui)
	restored_ui.display(main.run)
	var restored_graph = restored_ui.get_node("Margin/Layout/MapScroll/Route")
	check(restored_graph.step == Vector2(190, 120) and restored_graph.get_child(2).position.x == restored_graph.origin.x + 190, "Diseño de mapa guardado se usa al ejecutar")
	restored_ui.queue_free()
	main.run_ui.display(main.run)
	var graph = main.run_ui.get_node("Margin/Layout/MapScroll/Route")
	check(graph.get_child_count() == 9 and not graph.get_child(0).disabled and graph.get_child(8).disabled, "Nodos futuros bloqueados en la interfaz")
	graph.get_child(1).pressed.emit()
	await process_frame
	check(main.run.phase == "combat" and not main.run_ui.visible, "Nodo abre el combate real")
	check(main.ui.get_node("Margin/Battle/Actions/Retry").visible == false, "No reiniciar gratis combates de expedición")
	var index := -1
	for i in range(main.battle.hand.size()):
		if not main.battle.valid_targets(i).is_empty():
			index = i
			break
	check(index >= 0, "Hay una carta jugable")
	if index >= 0:
		main.ui.get_node("Margin/Battle/HandScroll/Cards").get_child(index).pressed.emit()
		main.ui.get_node("Margin/Battle/Targets").get_child(0).pressed.emit()
	var saved_state: Dictionary = main.run.export_state()
	check(canonical(Store.read(PATH).state) == canonical(saved_state), "Cada carta guarda su estado")
	main.ui.get_node("Margin/Battle/Actions/MenuButton").pressed.emit()
	check(main.run == null and not main.ui.get_node(menu + "RunActions/ContinueRun").disabled, "Salir conserva la expedición")
	var changed_catalog = main.catalog.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	changed_catalog.characters.assign(changed_catalog.characters.filter(func(character): return character.id == "noa"))
	changed_catalog.cards.assign(changed_catalog.cards.filter(func(card): return card.owner == "noa"))
	changed_catalog.team.assign([changed_catalog.characters[0]])
	var other_main = load("res://scenes/main.tscn").instantiate()
	other_main.catalog = changed_catalog
	other_main.save_path = PATH
	root.add_child(other_main)
	other_main.ui.get_node(menu + "RunActions/ContinueRun").pressed.emit()
	check(other_main.run != null and other_main.battle.character("lira") != null and not other_main.battle.card_data("corte").is_empty(), "La partida guardada no depende de IDs eliminados del catálogo actual")
	other_main.queue_free()
	main.ui.get_node(menu + "RunActions/ContinueRun").pressed.emit()
	await process_frame
	check(canonical(main.run.export_state()) == canonical(saved_state), "Continuar restaura exactamente mano, vida y RNG")
	for step in range(15):
		if main.run.phase in ["victory", "defeat"]: break
		if main.run.phase == "map":
			var selected: String = main.run.available()[0]
			for id in main.run.available():
				if main.run.node(id).type in ["combat", "rest"]: selected = id
			for button in graph.get_children():
				if button.text.ends_with(selected):
					button.pressed.emit()
					break
		if main.run.phase == "combat":
			Autoplay.fight(main.battle)
			await process_frame
			check(main.battle.result != "", "Combate de interfaz llega a un resultado")
			check(main.ui.get_node("Margin/Battle/Actions/ContinueBattle").visible, "Continuar tras resultado")
			main.ui.get_node("Margin/Battle/Actions/ContinueBattle").pressed.emit()
		if main.run.phase in ["reward", "rest", "event", "shop"]:
			var choices = main.run_ui.get_node("Margin/Layout/ChoiceScroll/Choices")
			var selected_button = choices.get_child(0)
			for button in choices.get_children():
				if (main.run.phase == "reward" and button.text.begins_with("Mejorar")) or (main.run.phase == "shop" and button.text == "Salir de la tienda"):
					selected_button = button
					break
			if main.run.phase == "event": selected_button = choices.get_child(1)
			selected_button.pressed.emit()
		await process_frame
	check(main.run.phase == "victory", "Recorrido completo de interfaz llega a victoria (" + main.run.phase + ")")
	check(main.run_ui.get_node("Margin/Layout/Message").text.contains("completada"), "Resumen de victoria visible")
	check(main.save_notice == "" and Store.read(PATH).has("state"), "Guardado válido al terminar")
	main.run_ui.get_node("Margin/Layout/Return").pressed.emit()
	main.ui.get_node(menu + "RunActions/ContinueRun").pressed.emit()
	check(main.run.phase == "victory", "Cargar una expedición terminada conserva el resumen")
	main.run_ui.get_node("Margin/Layout/Return").pressed.emit()
	main.ui.get_node("Margin/Menu/EnemyChoices").get_child(0).pressed.emit()
	check(main.run == null and main.battle.result == "", "Entrenamiento anterior conservado")
	main.queue_free()
	await process_frame
	for path in [PATH, PATH + ".bak", PATH + ".tmp", PATH + ".tscn"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("ESCENA ROGUELIKE: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)
