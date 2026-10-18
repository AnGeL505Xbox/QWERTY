@tool
extends EditorPlugin

const Catalog = preload("res://core/data/catalog.gd")
var dock: VBoxContainer
var list: ItemList
var report: RichTextLabel
var entries: Array[Resource] = []
var current_catalog: Resource

func _enter_tree() -> void:
	dock = VBoxContainer.new()
	dock.name = "Contenido"
	var title := Label.new()
	title.text = "Umbral · Edición visual"
	dock.add_child(title)
	_add_button("Abrir catálogo", func(): EditorInterface.edit_resource(load(Catalog.DEFAULT_PATH)))
	_add_button("Escenario 3D", func(): EditorInterface.open_scene_from_path("res://scenes/visuals/arena.tscn"))
	_add_button("Interfaz 2D", func(): EditorInterface.open_scene_from_path("res://scenes/ui/interface.tscn"))
	_add_button("Personaje visual", func(): EditorInterface.open_scene_from_path("res://scenes/visuals/actor.tscn"))
	_add_button("Plantilla de carta", func(): EditorInterface.open_scene_from_path("res://scenes/ui/card.tscn"))
	_add_button("Actualizar lista", _refresh)
	list = ItemList.new()
	list.custom_minimum_size = Vector2(220, 180)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.item_selected.connect(func(index): EditorInterface.edit_resource(entries[index]))
	dock.add_child(list)
	_add_button("Validar contenido", _validate)
	report = RichTextLabel.new()
	report.custom_minimum_size = Vector2(220, 140)
	report.text = "Selecciona un recurso para editarlo en el Inspector. Guarda los cambios antes de jugar."
	dock.add_child(report)
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)
	_refresh()

func _add_button(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	dock.add_child(button)

func _refresh() -> void:
	list.clear()
	entries.clear()
	var inspected = EditorInterface.get_inspector().get_edited_object()
	if inspected is RpgContentCatalog:
		current_catalog = inspected
	if current_catalog == null:
		current_catalog = load(Catalog.DEFAULT_PATH)
	var content = current_catalog
	for group in ["cards", "characters", "enemies", "statuses"]:
		for item in content.get(group):
			if item != null:
				entries.append(item)
				list.add_item("%s · %s" % [group, item.display_name])

func _validate() -> void:
	_refresh()
	var errors := Catalog.validate_resource(current_catalog)
	report.text = "Contenido válido. Puedes ejecutar el juego." if errors.is_empty() else "\n".join(errors)
	_refresh()

func _exit_tree() -> void:
	remove_control_from_docks(dock)
	dock.queue_free()
