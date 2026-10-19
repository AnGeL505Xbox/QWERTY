extends SceneTree
const Factory = preload("res://tools/editor/content_factory.gd")
const Authoring = preload("res://tools/editor/authoring.gd")
const Catalog = preload("res://core/data/catalog.gd")
const Expedition = preload("res://core/progression/expedition.gd")
const Validator = preload("res://core/save_system/run_validator.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		push_error(message)
		failures += 1
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var catalog: RpgContentCatalog = load("res://data/catalog.tres")
	var rules: RpgRunDefinition = load("res://data/progression/expedition.tres")
	var baseline := catalog.to_dict()
	var directory := "res://data/.editor-tests/" + str(Time.get_ticks_usec())
	var plans: Array = []
	for kind in Factory.GROUPS:
		var proposal := Factory.plan(kind, "prueba_" + kind, "Contenido de prueba", catalog, rules, null, "lira", false, directory)
		check(proposal.errors.is_empty(), "Crear " + kind + ": " + str(proposal.errors))
		plans.append(proposal)
	check(catalog.to_dict() == baseline, "Preparar propuestas no altera originales")
	check(not Factory.plan("card", "../invalido", "", catalog, rules).errors.is_empty(), "Rechazar ID peligroso")
	check(not Factory.plan("card", "valido", "", catalog, rules, null, "lira", false, "res://data/../core").errors.is_empty(), "Rechazar ruta exterior")
	var character := Factory.plan("character", "copia_lira", "Copia", catalog, rules, catalog.characters[0], "", false, directory)
	check(character.errors.is_empty(), "Duplicar personaje conserva referencias válidas")
	check(character.resource.deck[0].owner == "copia_lira", "Reasignar propietario de cartas copiadas")
	character.resource.deck[0].effects[0].amount += 1
	check(catalog.to_dict() == baseline, "Efectos de cartas duplicadas independientes")
	var event := Factory.plan("event", "copia_evento", "Copia", catalog, rules, rules.events[0], "", false, directory)
	event.resource.choices[0].gold_delta += 1
	check(event.resource.choices[0].gold_delta != rules.events[0].choices[0].gold_delta, "Opciones duplicadas independientes")
	for proposal in plans:
		check(Factory.persist_new(proposal) == "", "Guardar archivos nuevos")
		check(Factory.persist_new(proposal) != "", "Nunca sobrescribir archivos existentes")
		var restored = ResourceLoader.load(proposal.files[-1].path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
		check(restored != null and restored.id == proposal.resource.id, "Recargar contenido creado")
	# Guardado global en grafo aislado: ninguna referencia apunta a archivos de producción.
	var isolated: RpgContentCatalog = catalog.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	var isolated_rules: RpgRunDefinition = rules.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	isolated_rules.encounters = isolated.enemies.duplicate()
	check(ResourceSaver.save(isolated, directory + "/catalog.tres", ResourceSaver.FLAG_CHANGE_PATH) == OK, "Preparar catálogo aislado")
	check(ResourceSaver.save(isolated_rules, directory + "/rules.tres", ResourceSaver.FLAG_CHANGE_PATH) == OK, "Preparar reglas aisladas")
	isolated.take_over_path(directory + "/catalog.tres")
	isolated_rules.take_over_path(directory + "/rules.tres")
	var result := Authoring.save_all(isolated, isolated_rules)
	check(result.errors.is_empty() and result.saved.size() == 2, "Guardar todo sin escribir recursos originales")
	isolated.cards[0].owner = "inexistente"
	check(not Authoring.issues(isolated, isolated_rules).is_empty(), "Problemas de contenido localizables")
	check(Authoring.save_all(isolated, isolated_rules).saved.is_empty(), "Bloquear guardado inválido")
	var invalid_config := rules.to_dict()
	invalid_config.events[0].choices[0].card = "no_existe"
	check(not Validator.configuration(catalog.to_dict(), invalid_config).is_empty(), "Detectar carta desconocida en evento")
	invalid_config = rules.to_dict()
	invalid_config.rewards.card_choices = 6
	check(not Validator.configuration(catalog.to_dict(), invalid_config).is_empty(), "Detectar límite de ofertas inválido")
	var config := rules.to_dict()
	config.rewards.card_choices = 1
	config.rewards.upgrade_choices = 0
	config.rewards.allow_skip = false
	config.rewards.pool = ["corte"]
	var model = Expedition.new(catalog.to_dict(), config, 42, ["lira", "noa"])
	model.current = "0_0"
	model._open_rewards()
	check(model.offers.size() == 1 and model.offers[0].id == "corte", "Tabla personalizada controla cantidad y pool")
	model.config.rewards.card_choices = 0
	model._open_rewards()
	check(model.offers.size() == 1 and model.offers[0].action == "skip", "Salida de seguridad si no hay recompensas")
	model.phase = "event"
	model.current = "0_0"
	model.event_id = config.events[0].id
	var restored = Expedition.restore(model.export_state())
	check(restored.event_id == model.event_id and restored.active_event() == model.active_event(), "Restaurar evento activo e instantánea")
	var choice: Dictionary = model.active_event().choices[0]
	choice.gold = -999
	var before := JSON.stringify(model.export_state())
	check(not model.choose("event_choice", choice.id) and JSON.stringify(model.export_state()) == before, "Opción inasequible no muta partida")
	check(model.choose("event_leave") and model.phase == "map", "Abandonar evento sin bloqueo")
	var legacy := rules.to_dict()
	legacy.erase("events")
	legacy.erase("rewards")
	var old = Expedition.new(catalog.to_dict(), legacy, 42, ["lira", "noa"])
	check(not old.export_state().has("event_id"), "Guardado anterior conserva forma sin evento nuevo")
	check(Validator.validate(old.export_state()).is_empty(), "Formato anterior sigue siendo válido")
	var resumed = Expedition.restore(old.export_state())
	check(JSON.stringify(old.export_state()) == JSON.stringify(resumed.export_state()), "Restauración exacta de configuración anterior")
	old.phase = "event"
	old.current = "0_0"
	var gold: int = old.gold
	check(old.choose("risk") and old.gold == gold + int(legacy.event_gold), "Evento anterior conserva reglas originales")
	var modern = Expedition.new(catalog.to_dict(), rules.to_dict(), 42, ["lira", "noa"])
	modern.current = "0_0"
	modern.phase = "event"
	modern.event_id = modern.config.events[0].id
	var health: int = modern.party.lira.health
	check(modern.choose("event_choice", "risk") and modern.party.lira.health == health - 3 and modern.party.lira.stress == 3, "Efectos de evento aplican daño y estrés")
	check(not modern.choose("event_choice", "risk"), "No repetir premio de evento")
	var wizard = load("res://tools/editor/creation_dialog.gd").new()
	root.add_child(wizard)
	await process_frame
	wizard.open_for(catalog, rules, catalog.characters[0])
	check(wizard._proposal().errors.is_empty(), "Asistente prepara duplicación válida")
	check(wizard.get_child_count() > 0, "Asistente se construye en Godot")
	wizard.queue_free()
	await process_frame
	check(catalog.to_dict() == baseline, "Pruebas preservan catálogo de producción")
	_remove_tree(directory)
	print("HERRAMIENTAS: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)
func _remove_tree(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null: return
	for name in directory.get_files(): DirAccess.remove_absolute(path + "/" + name)
	for name in directory.get_directories(): _remove_tree(path + "/" + name)
	DirAccess.remove_absolute(path)
