extends SceneTree

const Editing = preload("res://tools/editor/editing.gd")
const Validator = preload("res://core/save_system/run_validator.gd")
const Route = preload("res://core/progression/route.gd")
const Expedition = preload("res://core/progression/expedition.gd")
const Store = preload("res://core/save_system/store.gd")
const Catalog = preload("res://core/data/catalog.gd")
const Autoplay = preload("res://tests/support/autoplay.gd")
var checks := 0
var failures := 0
var published: Array[Dictionary] = []
var histories: Array[UndoRedo] = []
const PATH = "user://test_editor_workflows"

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		push_error(message)
		failures += 1
func _initialize() -> void: call_deferred("run")
func canonical(value): return JSON.parse_string(JSON.stringify(value))
func apply(proposal: Dictionary) -> UndoRedo:
	var history := UndoRedo.new()
	histories.append(history)
	history.create_action("Aplicar borrador")
	for property in proposal.changes:
		history.add_do_property(proposal.target, property, proposal.changes[property])
		history.add_undo_property(proposal.target, property, proposal.target.get(property))
	history.commit_action()
	return history
func press(node: Node, text: String) -> void:
	if node is ConfirmationDialog and node.get_ok_button().text == text:
		node.confirmed.emit()
		return
	for child in node.get_children():
		if child is Button and child.text == text:
			child.pressed.emit()
			return
		press(child, text)
func run() -> void:
	var original: RpgContentCatalog = load("res://data/catalog.tres")
	var source_rules: RpgRunDefinition = load("res://data/progression/expedition.tres")
	var baseline := original.to_dict()
	var original_rules := source_rules.to_dict()
	var catalog: RpgContentCatalog = original.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	var rules: RpgRunDefinition = source_rules.duplicate(false)
	rules.encounters = catalog.enemies.duplicate()
	rules.events = []
	for event in source_rules.events: rules.events.append(Editing.event_draft(event))
	var character := catalog.characters[0]
	var original_deck := character.deck.duplicate()
	var dialog = load("res://tools/editor/deck_dialog.gd").new()
	root.add_child(dialog)
	dialog.proposal_ready.connect(func(proposal): published.append(proposal))
	dialog.open_for(catalog, character)
	check(dialog.pool.item_count > 0 and dialog.deck.item_count == original_deck.size(), "Mazo muestra cartas elegibles y copias iniciales")
	check(dialog.pool.cards.all(func(card): return card.owner == character.id), "Catálogo de mazo filtra propietario")
	dialog.pool.select(0)
	press(dialog, "Añadir copia →")
	check(dialog.draft.size() == original_deck.size() + 1 and character.deck == original_deck, "Añadir copia solo modifica borrador")
	var added: RpgCardDefinition = dialog.draft[-1]
	dialog.deck.card_dropped.emit(added, dialog.draft.size() - 1, 0)
	check(dialog.draft[0] == added and dialog.draft.size() == original_deck.size() + 1, "Arrastrar reordena sin duplicar")
	dialog.deck.select(0)
	press(dialog, "Quitar copia")
	check(dialog.draft.size() == original_deck.size(), "Quitar una copia")
	dialog.deck.card_dropped.emit(added, -1, 0)
	check(dialog.draft.size() == original_deck.size() + 1, "Arrastrar desde catálogo añade copia")
	check(not dialog.deck._can_drop_data(Vector2.ZERO, {"type": "rpg_deck_card", "card": catalog.characters[1].deck[0]}), "Arrastre rechaza carta ajena")
	press(dialog, "Aplicar borrador")
	check(published.size() == 1 and published[0].errors.is_empty(), "Botón Aplicar publica mazo válido")
	var history := apply(published.pop_back())
	check(character.deck.size() == original_deck.size() + 1, "Aplicar mazo conserva copias")
	history.undo()
	check(character.deck == original_deck, "Deshacer restaura mazo exacto")
	history.redo()
	check(character.deck.size() == original_deck.size() + 1, "Rehacer mazo")
	check(ResourceSaver.save(character, PATH + ".character.tres") == OK, "Guardar mazo editado")
	var loaded_character: RpgCharacterDefinition = ResourceLoader.load(PATH + ".character.tres", "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	check(loaded_character.to_dict() == character.to_dict(), "Mazo y especial sobreviven recarga")
	var battle = preload("res://core/combat/battle.gd").new(catalog.to_dict(), 42, 0, [character.id])
	check(battle.hand.size() + battle.draw_pile.size() == character.deck.size(), "Copias editadas llegan al combate")
	history.undo()
	var empty: Array[RpgCardDefinition] = []
	check(not Editing.deck_proposal(catalog, character, empty, character.special).errors.is_empty(), "Mazo vacío rechazado")
	var foreign := original_deck.duplicate()
	foreign.append(catalog.characters[1].deck[0])
	check(not Editing.deck_proposal(catalog, character, foreign, character.special).errors.is_empty(), "Mazo ajeno rechazado")
	check(not Editing.deck_proposal(catalog, character, original_deck, catalog.characters[1].special).errors.is_empty(), "Especial ajeno rechazado")
	foreign = original_deck.duplicate()
	foreign[0] = foreign[0].duplicate(false)
	check(not Editing.deck_proposal(catalog, character, foreign, character.special).errors.is_empty(), "Carta con ID igual sin registrar rechazada")
	dialog.open_for(catalog, character)
	dialog.draft.clear()
	press(dialog, "Aplicar borrador")
	check(published.is_empty() and dialog.visible, "Borrador inválido permanece abierto y no se aplica")
	dialog.hide()
	dialog.queue_free()
	var event_dialog = load("res://tools/editor/event_dialog.gd").new()
	root.add_child(event_dialog)
	event_dialog.proposal_ready.connect(func(proposal): published.append(proposal))
	var target := rules.events[0]
	var before_event := target.to_dict()
	event_dialog.open_for(catalog, rules, target)
	event_dialog.gold.value = 31
	event_dialog.choice_label.text = "Aceptar prueba"
	event_dialog.choice_label.text_changed.emit("Aceptar prueba")
	check(target.to_dict() == before_event, "Formulario de evento no muta original")
	press(event_dialog, "+ Opción")
	check(event_dialog.draft.choices.size() == target.choices.size() + 1, "Añadir decisión")
	press(event_dialog, "↑")
	check(event_dialog.selected == 1, "Ordenar decisiones")
	press(event_dialog, "Quitar")
	check(event_dialog.draft.choices.size() == target.choices.size(), "Quitar decisión")
	event_dialog.name_input.text = "Fuente editada"
	press(event_dialog, "Aplicar borrador")
	check(published.size() == 1, "Evento válido se publica desde botón")
	history = apply(published.pop_back())
	check(target.display_name == "Fuente editada" and target.choices[0].gold_delta == 31, "Aplicar decisiones editadas")
	event_dialog.draft.choices[0].gold_delta = 99
	check(target.choices[0].gold_delta == 31, "Propuesta aplicada independiente del borrador")
	history.undo()
	check(target.to_dict() == before_event, "Deshacer evento restaura texto y opciones")
	history.redo()
	var invalid_event := Editing.event_draft(target)
	invalid_event.choices[1].id = invalid_event.choices[0].id
	check(not Editing.event_proposal(catalog, rules, target, invalid_event).errors.is_empty(), "IDs de opción repetidos rechazados")
	invalid_event.choices.clear()
	check(not Editing.event_proposal(catalog, rules, target, invalid_event).errors.is_empty(), "Evento sin decisiones rechazado")
	event_dialog.queue_free()
	var route_dialog = load("res://tools/editor/route_dialog.gd").new()
	root.add_child(route_dialog)
	route_dialog.proposal_ready.connect(func(proposal): published.append(proposal))
	route_dialog.open_for(catalog, rules)
	check(route_dialog.procedural and route_dialog.graph.get_connection_list().size() == 14, "Vista de ruta procedural con conexiones")
	route_dialog.rows.value = 4
	press(route_dialog, "Regenerar borrador")
	check(not route_dialog.procedural and route_dialog.draft.size() == 7, "Generar borrador de cuatro etapas")
	var graph_node: GraphNode = route_dialog.graph.get_node("0_0")
	var type_input: OptionButton = graph_node.get_child(0).get_child(0)
	type_input.select(2)
	type_input.item_selected.emit(2)
	check(route_dialog.draft[0].type == "event", "Selector visual cambia tipo de nodo")
	route_dialog.graph.disconnection_request.emit(&"0_0", 0, &"1_0", 0)
	route_dialog.graph.disconnection_request.emit(&"0_0", 0, &"1_1", 0)
	check(route_dialog.get_ok_button().disabled, "Nodo sin salida bloquea aplicación")
	route_dialog.graph.connection_request.emit(&"0_0", 0, &"1_1", 0)
	check(not route_dialog.get_ok_button().disabled, "Conectar etapa siguiente repara ruta")
	var links: PackedStringArray = route_dialog.draft[0].links.duplicate()
	route_dialog.graph.connection_request.emit(&"0_0", 0, &"2_0", 0)
	check(route_dialog.draft[0].links == links, "Conexión que salta etapa rechazada")
	press(route_dialog, "Aplicar borrador")
	check(published.size() == 1, "Aplicar ruta visual válida")
	history = apply(published.pop_back())
	check(rules.rows == 4 and rules.route_nodes.size() == 7, "Ruta llega a configuración")
	history.undo()
	check(rules.rows == source_rules.rows and rules.route_nodes.is_empty(), "Deshacer recupera ruta procedural")
	history.redo()
	var config := rules.to_dict()
	check(Validator.resource_configuration(catalog, rules).is_empty(), "Ruta personalizada válida como Resources")
	var generated := Route.generate(42, config)
	check(generated[0].type == "event" and generated[0].links == ["1_1"], "Generador usa nodos y enlaces del editor")
	check(generated == Route.generate(42, config), "Ruta personalizada reproducible por semilla")
	var edited_nodes := Editing.route_draft(rules, 42)
	edited_nodes[1].enemy = rules.encounters[0]
	var forced := Editing.route_proposal(catalog, rules, edited_nodes, rules.rows)
	apply(forced)
	config = rules.to_dict()
	check(Route.generate(11, config)[1].enemy == rules.encounters[0].id and Route.generate(88, config)[1].enemy == rules.encounters[0].id, "Enemigo fijado conserva selección entre semillas")
	var broken := config.duplicate(true)
	broken.route_nodes[0].links = ["0_1"]
	check(not Validator.configuration(catalog.to_dict(), broken).is_empty(), "Ciclo rechazado")
	broken = config.duplicate(true)
	broken.route_nodes[0].links = ["1_0"]
	broken.route_nodes[1].links = ["1_0"]
	check(not Validator.configuration(catalog.to_dict(), broken).is_empty(), "Nodo inaccesible rechazado")
	broken = config.duplicate(true)
	broken.route_nodes[0].type = "boss"
	check(not Validator.configuration(catalog.to_dict(), broken).is_empty(), "Jefe intermedio rechazado")
	broken = config.duplicate(true)
	broken.route_nodes[1].enemy = "desconocido"
	check(not Validator.configuration(catalog.to_dict(), broken).is_empty(), "Enemigo de ruta desconocido rechazado")
	broken = config.duplicate(true)
	broken.route_nodes[0] = {}
	check(not Validator.configuration(catalog.to_dict(), broken).is_empty(), "Nodo malformado rechazado")
	check(Route.generate(42, broken).is_empty(), "Generador rechaza ruta malformada sin excepción")
	var large_rules: RpgRunDefinition = rules.duplicate(false)
	large_rules.route_nodes = []
	large_rules.rows = 8
	var large := Editing.route_draft(large_rules, 42)
	check(large.size() == 15 and Editing.route_proposal(catalog, rules, large, 8).errors.is_empty(), "Ruta de ocho etapas válida")
	route_dialog.open_for(catalog, rules)
	route_dialog.seed_input.value = 88
	check(route_dialog.draft[0].type == "event" and route_dialog.draft[0].links == PackedStringArray(["1_1"]), "Cambiar semilla conserva ruta personalizada")
	check(ResourceSaver.save(rules, PATH + ".tres") == OK, "Guardar reglas con nodos tipados")
	var loaded: RpgRunDefinition = ResourceLoader.load(PATH + ".tres", "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	check(canonical(loaded.to_dict()) == canonical(rules.to_dict()), "Ruta y eventos conservados tras recargar Resources")
	var model = Expedition.new(catalog.to_dict(), config, 42, ["lira", "noa"])
	check(model.enter("0_0") and model.phase == "event", "Expedición entra al evento colocado visualmente")
	var initial_gold: int = model.gold
	check(model.choose("event_choice", "risk") and model.gold == initial_gold + 31, "Evento editado aplica efecto en juego")
	check(model.available() == ["1_1"], "Juego respeta conexión editada")
	check(Validator.validate(model.export_state()).is_empty(), "Estado de ruta personalizada válido")
	check(Store.write(PATH + ".json", model.export_state()) == "", "Guardar expedición personalizada")
	var saved := Store.read(PATH + ".json")
	check(saved.has("state"), "Leer expedición personalizada")
	var restored = Expedition.restore(saved.state)
	check(canonical(restored.export_state()) == canonical(model.export_state()), "Carga exacta con mapa y eventos personalizados")
	# Seguir la ruta real con cartas y turnos; el carril derecho evita élite para esta prueba.
	for step in range(10):
		if restored.phase in ["victory", "defeat"]: break
		if restored.phase == "map": restored.enter(restored.available()[-1])
		if restored.phase == "combat":
			Autoplay.fight(restored.battle)
			restored.sync_party()
			restored.finish_battle()
		if restored.phase == "reward": restored.choose("skip")
		elif restored.phase == "rest": restored.choose("heal")
		elif restored.phase == "event": restored.choose("event_leave")
		elif restored.phase == "shop": restored.choose("leave")
		check(Validator.validate(restored.export_state()).is_empty(), "Continuación personalizada válida")
	check(restored.phase == "victory", "Expedición personalizada completa con cartas y jefe")
	route_dialog.open_for(catalog, rules)
	press(route_dialog, "Usar ruta procedural")
	press(route_dialog, "Aplicar borrador")
	apply(published.pop_back())
	check(not rules.to_dict().has("route_nodes"), "Volver al formato procedural sin campo nuevo")
	var old = Expedition.new(original.to_dict(), original_rules, 42, ["lira", "noa"])
	check(Validator.validate(old.export_state()).is_empty() and not old.config.has("route_nodes"), "Partida procedural anterior válida")
	check(canonical(Expedition.restore(old.export_state()).export_state()) == canonical(old.export_state()), "Partida anterior conserva instantánea exacta")
	route_dialog.queue_free()
	await process_frame
	check(original.to_dict() == baseline and source_rules.to_dict() == original_rules, "Pruebas conservan contenido de producción")
	for suffix in [".tres", ".character.tres", ".json", ".json.bak", ".json.tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	for undo_history in histories:
		undo_history.clear_history()
		undo_history.free()
	histories.clear()
	print("EDITORES: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)
