@tool
extends RefCounted

const Editing = preload("res://tools/editor/editing.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		push_error(message)
		failures += 1

# Se ejecuta desde el plugin en una instancia nueva del editor. Solo modifica copias en memoria.
func run(plugin: EditorPlugin) -> void:
	await plugin.get_tree().process_frame
	var source: RpgContentCatalog = load("res://data/catalog.tres")
	var source_rules: RpgRunDefinition = load("res://data/progression/expedition.tres")
	var before := source.to_dict()
	var before_rules := source_rules.to_dict()
	var catalog: RpgContentCatalog = source.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	var rules: RpgRunDefinition = source_rules.duplicate(false)
	rules.encounters = catalog.enemies.duplicate()
	rules.events = []
	for event in source_rules.events: rules.events.append(Editing.event_draft(event))
	plugin.current_catalog = catalog
	plugin.current_run_rules = rules
	plugin.selected_resource = catalog.characters[0]
	EditorInterface.edit_resource(plugin.selected_resource)
	plugin._open_editor("deck")
	var deck_editor = plugin.editors[0]
	check(deck_editor.visible, "Botón del plugin abre editor de mazo")
	var character := catalog.characters[0]
	var deck := character.deck.duplicate()
	deck_editor.deck.card_dropped.emit(character.deck[0], -1, 0)
	deck_editor.confirmed.emit()
	check(character.deck.size() == deck.size() + 1, "Aplicar formulario usa historial nativo")
	var manager := plugin.get_undo_redo()
	var history := manager.get_history_undo_redo(manager.get_object_history_id(character))
	check(history.has_undo(), "Historial nativo contiene acción")
	history.undo()
	check(character.deck == deck, "Deshacer nativo restaura mazo")
	history.redo()
	check(character.deck.size() == deck.size() + 1, "Rehacer nativo restaura edición")
	history.undo()
	history.clear_history()
	var event := rules.events[0]
	plugin.selected_resource = event
	plugin._open_editor("event")
	var event_editor = plugin.editors[1]
	check(event_editor.visible, "Botón del plugin abre evento")
	var old_name := event.display_name
	event_editor.name_input.text = "Evento de prueba nativa"
	event_editor.confirmed.emit()
	check(event.display_name == "Evento de prueba nativa", "Aplicar nombre desde formulario nativo")
	history = manager.get_history_undo_redo(manager.get_object_history_id(event))
	history.undo()
	check(event.display_name == old_name, "Deshacer nativo restaura evento")
	var found := false
	for index in range(plugin.list.item_count):
		if plugin.entries[index] == event and old_name in plugin.list.get_item_text(index): found = true
	check(found, "Lista del panel se actualiza después de Deshacer")
	history.redo()
	check(event.display_name == "Evento de prueba nativa", "Rehacer nativo de evento")
	history.undo()
	history.clear_history()
	plugin._open_editor("route")
	var route_editor = plugin.editors[2]
	check(route_editor.visible, "Botón del plugin abre grafo")
	route_editor.rows.value = 4
	route_editor._generate()
	route_editor.confirmed.emit()
	check(rules.rows == 4 and rules.route_nodes.size() == 7, "Formulario de ruta aplicado por plugin")
	history = manager.get_history_undo_redo(manager.get_object_history_id(rules))
	history.undo()
	check(rules.rows == source_rules.rows and rules.route_nodes.is_empty(), "Deshacer nativo restaura configuración de ruta")
	history.redo()
	check(rules.rows == 4 and rules.route_nodes.size() == 7, "Rehacer nativo de ruta")
	history.undo()
	history.clear_history()
	check(source.to_dict() == before and source_rules.to_dict() == before_rules, "Prueba nativa conserva archivos y Resources de producción")
	print("EDITOR NATIVO: %d comprobaciones, %d fallos" % [checks, failures])
	plugin.get_tree().quit(1 if failures else 0)
