extends SceneTree

const Catalog = preload("res://core/data/catalog.gd")
const Battle = preload("res://core/combat/battle.gd")
var checks := 0
var failures := 0
var temporary_paths: Array[String] = []

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		push_error(message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func _persist(resource: Resource, name: String):
	var path := "user://visual_test_" + name
	temporary_paths.append(path)
	check(ResourceSaver.save(resource, path) == OK, "Guardar " + name)
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)

func run() -> void:
	var original: RpgContentCatalog = load(Catalog.DEFAULT_PATH)
	var baseline := original.to_dict()
	var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/content.json"))
	for status in legacy.statuses.values():
		status["attack"] = status.get("attack", 0.0)
		status["defense"] = status.get("defense", 0.0)
	check(JSON.parse_string(JSON.stringify(baseline)) == legacy, "Migración conserva todo el contenido de fase 4")
	check(Catalog.validate_resource(original).is_empty(), "Catálogo Resources válido")
	var legacy_battle := Battle.new(legacy, 123)
	var resource_battle := Battle.new(baseline, 123)
	var actions := 0
	var equivalent := true
	for round_index in range(8):
		if resource_battle.result != "":
			break
		for play_index in range(4):
			for index in range(resource_battle.hand.size()):
				var targets := resource_battle.valid_targets(index)
				if not targets.is_empty():
					actions += 1
					resource_battle.play(index, targets[0])
					legacy_battle.play(index, targets[0])
					break
		resource_battle.end_turn()
		legacy_battle.end_turn()
		equivalent = equivalent and resource_battle.state_snapshot() == legacy_battle.state_snapshot() and resource_battle.hand == legacy_battle.hand and resource_battle.result == legacy_battle.result
		for i in range(resource_battle.team.size()):
			equivalent = equivalent and resource_battle.team[i].energy == legacy_battle.team[i].energy
	check(actions > 0 and equivalent, "Combate reproducible idéntico usando JSON o Resources")
	var edited: RpgContentCatalog = original.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	edited.cards[0].cost = 2
	edited.cards[0].effects[0].amount = 11
	edited.characters[0].health = 55
	edited.enemies[0].health = 45
	edited.enemies[0].pattern[0].amount = 8
	edited.hand_size = 4
	check(original.to_dict() == baseline, "Editar una copia no modifica el original")
	var card := RpgCardDefinition.new()
	card.id = "prueba_editor"
	card.display_name = "Creada desde Resources"
	card.cost = 0
	card.owner = "lira"
	card.illustration = load("res://visuals/traveler.svg")
	var effect := RpgEffectDefinition.new()
	effect.amount = 9
	card.effects.append(effect)
	edited.cards.append(card)
	edited.characters[0].deck.append(card)
	check(Catalog.validate_resource(edited).is_empty(), "Nueva carta registrada y añadida al mazo")
	var restored: RpgContentCatalog = _persist(edited, "catalog.tres")
	check(restored != null and Catalog.validate_resource(restored).is_empty(), "Catálogo editado recargado y validado")
	var battle := Battle.new(restored.to_dict(), 14)
	check(battle.health == 55 and battle.enemy_health == 45 and battle.hand.size() == 4 and battle.intent.amount == 8, "Estadísticas y balance editados llegan al combate")
	battle.hand = ["corte", "prueba_editor"]
	battle.play(0, "enemy")
	check(battle.enemy_health == 34 and battle.energy == 1, "Coste y daño editados llegan al combate")
	battle.play(0, "enemy")
	check(battle.enemy_health == 25, "Nueva carta Resource funcional")
	var invalid: RpgContentCatalog = original.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	invalid.cards.append(invalid.cards[0])
	check(not Catalog.validate_resource(invalid).is_empty(), "ID duplicado produce error recuperable")
	invalid = original.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	invalid.cards[0].owner = "desconocido"
	check(not Catalog.validate_resource(invalid).is_empty(), "Propietario desconocido detectado")
	invalid = original.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	invalid.cards[0].effects.append(null)
	check(not Catalog.validate_resource(invalid).is_empty(), "Efecto nulo detectado sin excepción")
	invalid = original.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	invalid.team.append(invalid.team[0])
	check(not Catalog.validate_resource(invalid).is_empty(), "Equipo duplicado detectado")
	invalid = original.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	invalid.characters[0].deck[0] = invalid.cards[0].duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	check(not Catalog.validate_resource(invalid).is_empty(), "Referencia con ID igual pero recurso distinto detectada")
	invalid = original.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	invalid.statuses.append(invalid.statuses[0])
	check(not Catalog.validate_resource(invalid).is_empty(), "Estado duplicado detectado antes de colapsar diccionario")
	var arena = load("res://scenes/visuals/arena.tscn").instantiate()
	root.add_child(arena)
	check(arena.get_node("WorldEnvironment").environment.ambient_light_source == Environment.AMBIENT_SOURCE_COLOR, "Iluminación ambiental conserva la configuración original")
	arena.motion_enabled = false
	arena.camera.position.x = 1.75
	arena.get_node("Stage/Floor").position.y = -1.4
	arena.get_node("AllySlots/Slot1").position.x = -2.1
	var packed_arena := PackedScene.new()
	check(packed_arena.pack(arena) == OK, "Empaquetar escenario modificado")
	var arena_scene: PackedScene = _persist(packed_arena, "arena.tscn")
	var loaded_arena = arena_scene.instantiate()
	root.add_child(loaded_arena)
	loaded_arena.set_team(battle.team)
	loaded_arena.set_enemy(battle.enemy)
	await process_frame
	check(is_equal_approx(loaded_arena.camera.position.x, 1.75), "La cámara conserva la posición editada")
	check(is_equal_approx(loaded_arena.get_node("Stage/Floor").position.y, -1.4), "El suelo conserva la posición editada")
	check(is_equal_approx(loaded_arena.actors.lira.global_position.x, -2.1), "El personaje usa el marcador editado")
	var actor = load("res://scenes/visuals/actor.tscn").instantiate()
	actor.get_node("Pivot/VisualOffset").scale = Vector3(0.8, 0.8, 0.8)
	var packed_actor := PackedScene.new()
	check(packed_actor.pack(actor) == OK, "Empaquetar personaje modificado")
	var actor_scene: PackedScene = _persist(packed_actor, "actor.tscn")
	var loaded_actor = actor_scene.instantiate()
	root.add_child(loaded_actor)
	loaded_actor.setup("lira", "Lira", restored.characters[0].visual_profile)
	loaded_actor.play_animation("attack")
	check(loaded_actor.get_node("Pivot/VisualOffset").scale == Vector3(0.8, 0.8, 0.8), "La animación respeta el ajuste visual editado")
	var card_view = load("res://scenes/ui/card.tscn").instantiate()
	card_view.custom_minimum_size.x = 333
	var packed_card := PackedScene.new()
	check(packed_card.pack(card_view) == OK, "Empaquetar plantilla de carta modificada")
	var card_scene: PackedScene = _persist(packed_card, "card.tscn")
	var interface = load("res://scenes/ui/interface.tscn").instantiate()
	interface.get_node("Scroll/Margin/Menu/Title").text = "Título editado"
	interface.get_node("Scroll/Margin").add_theme_constant_override("margin_left", 42)
	interface.get_node("Scroll/Margin/Battle/Actions/EndTurn").text = "Finalizar ronda"
	interface.card_scene = card_scene
	var packed_ui := PackedScene.new()
	check(packed_ui.pack(interface) == OK, "Empaquetar interfaz modificada")
	var ui_scene: PackedScene = _persist(packed_ui, "interface.tscn")
	var main = load("res://scenes/main.tscn").instantiate()
	main.catalog = restored
	var old_ui = main.get_node("Interface")
	main.remove_child(old_ui)
	old_ui.free()
	var loaded_ui = ui_scene.instantiate()
	loaded_ui.name = "Interface"
	main.add_child(loaded_ui)
	root.add_child(main)
	await process_frame
	check(loaded_ui.get_node("Scroll/Margin/Menu/Title").text == "Título editado" and loaded_ui.get_node("Scroll/Margin").get_theme_constant("margin_left") == 42, "El menú conserva texto y márgenes editados")
	# Usar las señales reales de botones, no solo llamar al controlador.
	loaded_ui.get_node("Scroll/Margin/Menu/EnemyChoices").get_child(1).pressed.emit()
	await process_frame
	check(main.battle.enemy.id == "custodio", "Botón dinámico elige el enemigo correcto")
	main.battle.hand = ["prueba_editor"]
	main._render()
	var rendered = loaded_ui.get_node("Scroll/Margin/Battle/HandScroll/Cards").get_child(0)
	check(rendered.custom_minimum_size.x == 333 and rendered.get_node("Margin/Content/Name").text == card.display_name, "La carta usa plantilla y contenido editados")
	check(rendered.get_node("Margin/Content/Artwork").texture != null, "Ilustración del Resource visible en la carta")
	check(loaded_ui.get_node("Scroll/Margin/Battle/Actions/EndTurn").text == "Finalizar ronda", "Se conserva el texto del botón estático")
	rendered.pressed.emit()
	await process_frame
	loaded_ui.get_node("Scroll/Margin/Battle/Targets").get_child(0).pressed.emit()
	check(main.battle.enemy_health == 33, "Carta y confirmación funcionan desde botones de escena")
	var bad_main = load("res://scenes/main.tscn").instantiate()
	bad_main.catalog = invalid
	root.add_child(bad_main)
	await process_frame
	check(bad_main.battle == null and bad_main.ui.get_node("Scroll/Margin/Errors").visible, "Contenido inválido muestra errores sin iniciar combate")
	check(original.to_dict() == baseline, "Pruebas no alteran el contenido del proyecto")
	for node in [arena, loaded_arena, actor, loaded_actor, card_view, interface, main, bad_main]:
		node.queue_free()
	await process_frame
	for path in temporary_paths:
		DirAccess.remove_absolute(path)
	print("EDICIÓN VISUAL: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)
