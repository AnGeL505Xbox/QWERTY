@tool
extends EditorPlugin

const Catalog = preload("res://core/data/catalog.gd")
const Authoring = preload("res://tools/editor/authoring.gd")
const Factory = preload("res://tools/editor/content_factory.gd")
const Wizard = preload("res://tools/editor/creation_dialog.gd")
const LABELS = {"card": "Cartas", "character": "Personajes", "enemy": "Enemigos", "status": "Estados", "reward": "Recompensas", "event": "Eventos"}
var dock: ScrollContainer
var body: VBoxContainer
var list: ItemList
var report: RichTextLabel
var issues_list: ItemList
var search: LineEdit
var category: OptionButton
var wizard: ConfirmationDialog
var preview: AcceptDialog
var preview_text: RichTextLabel
var entries: Array[Resource] = []
var problem_resources: Array[Resource] = []
var current_catalog: RpgContentCatalog
var current_run_rules: RpgRunDefinition
var selected_resource: Resource

func _enter_tree() -> void:
	dock = ScrollContainer.new()
	dock.name = "Contenido"
	dock.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dock.add_child(body)
	var title := Label.new()
	title.text = "Umbral · Herramientas de contenido"
	body.add_child(title)
	_add_button("Catálogo", func(): EditorInterface.edit_resource(load(Catalog.DEFAULT_PATH)))
	_add_button("Expedición", func(): EditorInterface.edit_resource(load("res://data/progression/expedition.tres")))
	for path in ["scenes/visuals/arena.tscn", "scenes/ui/interface.tscn", "scenes/visuals/actor.tscn", "scenes/ui/card.tscn", "scenes/exploration/run_ui.tscn"]:
		_add_button(path.get_file(), func(): EditorInterface.open_scene_from_path("res://" + path))
	search = LineEdit.new()
	search.placeholder_text = "Buscar por nombre, ID o ruta"
	search.text_changed.connect(func(_text): _refresh())
	body.add_child(search)
	category = OptionButton.new()
	category.add_item("Todos")
	for kind in LABELS:
		category.add_item(LABELS[kind])
		category.set_item_metadata(category.item_count - 1, kind)
	category.item_selected.connect(func(_index): _refresh())
	body.add_child(category)
	_add_button("Actualizar lista", _refresh)
	list = ItemList.new()
	list.custom_minimum_size = Vector2(230, 170)
	list.item_selected.connect(_select)
	body.add_child(list)
	_add_button("Crear recurso…", func(): _open_wizard(false))
	_add_button("Duplicar selección…", func(): _open_wizard(true))
	_add_button("Vista previa de selección", _preview_selection)
	_add_button("Validar contenido", _validate)
	issues_list = ItemList.new()
	issues_list.custom_minimum_size = Vector2(230, 100)
	issues_list.item_selected.connect(func(index):
		if problem_resources[index] != null: EditorInterface.edit_resource(problem_resources[index]))
	body.add_child(issues_list)
	_add_button("Guardar contenido", _save)
	report = RichTextLabel.new()
	report.custom_minimum_size = Vector2(230, 110)
	report.text = "Crea o selecciona contenido. Guarda los cambios antes de jugar."
	body.add_child(report)
	wizard = Wizard.new()
	EditorInterface.get_base_control().add_child(wizard)
	wizard.resource_created.connect(_register)
	preview = AcceptDialog.new()
	preview.title = "Vista previa de contenido"
	preview_text = RichTextLabel.new()
	preview_text.custom_minimum_size = Vector2(560, 360)
	preview.add_child(preview_text)
	EditorInterface.get_base_control().add_child(preview)
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)
	_refresh()

func _add_button(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	body.add_child(button)

func _contexts() -> void:
	var inspected = EditorInterface.get_inspector().get_edited_object()
	if inspected is RpgContentCatalog: current_catalog = inspected
	if inspected is RpgRunDefinition: current_run_rules = inspected
	if current_catalog == null: current_catalog = load(Catalog.DEFAULT_PATH)
	if current_run_rules == null: current_run_rules = load("res://data/progression/expedition.tres")

func _refresh() -> void:
	_contexts()
	list.clear()
	entries.clear()
	var candidates: Array = []
	for group in ["cards", "characters", "enemies", "statuses"]: candidates.append_array(current_catalog.get(group))
	candidates.append(current_run_rules.boss)
	candidates.append(current_run_rules.reward_table)
	candidates.append_array(current_run_rules.events)
	var filter_kind := str(category.get_item_metadata(category.selected)) if category.selected > 0 else ""
	var query := search.text.to_lower()
	for resource in candidates:
		if resource == null: continue
		var kind := Factory.kind_of(resource)
		if filter_kind != "" and kind != filter_kind: continue
		var label := "%s · %s [%s]" % [LABELS.get(kind, kind), resource.display_name, resource.id]
		if query != "" and not (label + " " + resource.resource_path).to_lower().contains(query): continue
		entries.append(resource)
		list.add_item(label)
		list.set_item_tooltip(entries.size() - 1, resource.resource_path)

func _select(index: int) -> void:
	selected_resource = entries[index]
	EditorInterface.edit_resource(selected_resource)

func _open_wizard(duplicate: bool) -> void:
	_contexts()
	if duplicate and (selected_resource == null or Factory.kind_of(selected_resource) == ""):
		report.text = "Selecciona un recurso de la lista para duplicarlo."
		return
	wizard.open_for(current_catalog, current_run_rules, selected_resource if duplicate else null)

func _register(proposal: Dictionary) -> void:
	var history := get_undo_redo()
	history.create_action("Registrar " + str(proposal.resource.display_name), UndoRedo.MERGE_DISABLE, current_catalog)
	for group in ["cards", "characters", "enemies", "statuses"]:
		history.add_do_property(current_catalog, group, proposal.catalog.get(group).duplicate())
		history.add_undo_property(current_catalog, group, current_catalog.get(group).duplicate())
	for property in ["events", "reward_table"]:
		history.add_do_property(current_run_rules, property, proposal.rules.get(property))
		history.add_undo_property(current_run_rules, property, current_run_rules.get(property))
	history.add_do_method(current_catalog, "emit_changed")
	history.add_undo_method(current_catalog, "emit_changed")
	history.add_do_method(current_run_rules, "emit_changed")
	history.add_undo_method(current_run_rules, "emit_changed")
	history.add_do_method(self, "_refresh")
	history.add_undo_method(self, "_refresh")
	history.commit_action()
	EditorInterface.get_resource_filesystem().scan()
	selected_resource = proposal.resource
	EditorInterface.edit_resource(selected_resource)
	report.text = "Archivos creados y registro preparado. Puedes deshacer el registro; los archivos se conservan. Pulsa Guardar contenido para persistir catálogo y reglas."

func _validate() -> void:
	_contexts()
	issues_list.clear()
	problem_resources.clear()
	var problems := Authoring.issues(current_catalog, current_run_rules)
	for problem in problems:
		issues_list.add_item(problem.message)
		problem_resources.append(problem.resource)
	report.text = "Contenido válido." if problems.is_empty() else "%d errores. Selecciona uno para abrir el recurso." % problems.size()
	_refresh()

func _save() -> void:
	_contexts()
	var result := Authoring.save_all(current_catalog, current_run_rules)
	_validate()
	report.text = "Guardados %d archivos de contenido." % result.saved.size() if result.errors.is_empty() else "No se completó el guardado:\n" + "\n".join(result.errors)
	EditorInterface.get_resource_filesystem().scan()

func _preview_selection() -> void:
	if selected_resource == null:
		report.text = "Selecciona un recurso."
		return
	if selected_resource is RpgCardDefinition:
		EditorInterface.open_scene_from_path("res://scenes/ui/card.tscn")
		var root = EditorInterface.get_edited_scene_root()
		if root != null and root.has_method("show_card"): root.preview_card = selected_resource
	var lines: Array[String] = [selected_resource.display_name, selected_resource.resource_path, ""]
	if selected_resource is RpgEventDefinition:
		lines.append(selected_resource.description)
		for choice in selected_resource.choices:
			if choice != null: lines.append("• %s\n  Oro %+d · PV %+d · Estrés %+d · Carta %s" % [choice.label, choice.gold_delta, choice.health_delta, choice.stress_delta, choice.card.id if choice.card != null else "ninguna"])
	elif selected_resource is RpgRewardTable:
		lines.append("Cartas: %d · Mejoras: %d · Omitir: %s" % [selected_resource.card_choices, selected_resource.upgrade_choices, selected_resource.allow_skip])
		lines.append("Pool: todas las cartas del equipo" if selected_resource.cards.is_empty() else ", ".join(selected_resource.cards.map(func(card): return card.id if card != null else "NULO")))
	elif selected_resource.has_method("to_dict"): lines.append(JSON.stringify(selected_resource.to_dict(), "  "))
	preview_text.text = "\n".join(lines)
	preview.popup_centered()

func _exit_tree() -> void:
	remove_control_from_docks(dock)
	dock.queue_free()
	wizard.queue_free()
	preview.queue_free()
