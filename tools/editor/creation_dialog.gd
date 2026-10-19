@tool
extends ConfirmationDialog

signal resource_created(proposal: Dictionary)
const DialogLayout = preload("res://tools/editor/dialog_layout.gd")
const Factory = preload("res://tools/editor/content_factory.gd")
const KINDS = ["card", "character", "enemy", "status", "reward", "event"]
var catalog: RpgContentCatalog
var rules: RpgRunDefinition
var source: Resource
var type_input: OptionButton
var id_input: LineEdit
var title_input: LineEdit
var owner_input: OptionButton
var activate: CheckBox
var details: RichTextLabel

func _ready() -> void:
	title = "Crear contenido"
	dialog_hide_on_ok = false
	get_ok_button().text = "Crear y registrar"
	var body := VBoxContainer.new()
	body.custom_minimum_size = Vector2(540, 400)
	DialogLayout.wrap(self, body)
	type_input = OptionButton.new()
	for label in ["Carta", "Personaje", "Enemigo", "Estado", "Tabla de recompensas", "Evento"]: type_input.add_item(label)
	body.add_child(type_input)
	id_input = LineEdit.new()
	id_input.placeholder_text = "ID único, por ejemplo mi_carta"
	body.add_child(id_input)
	title_input = LineEdit.new()
	title_input.placeholder_text = "Nombre visible"
	body.add_child(title_input)
	owner_input = OptionButton.new()
	body.add_child(owner_input)
	activate = CheckBox.new()
	activate.text = "Activar esta tabla en la expedición (sustituye la referencia actual)"
	body.add_child(activate)
	details = RichTextLabel.new()
	details.custom_minimum_size = Vector2(540, 240)
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(details)
	for field in [id_input, title_input]: field.text_changed.connect(func(_value): _preview())
	type_input.item_selected.connect(func(_index): _preview())
	owner_input.item_selected.connect(func(_index): _preview())
	activate.toggled.connect(func(_enabled): _preview())
	confirmed.connect(_create)

func open_for(content: RpgContentCatalog, run_rules: RpgRunDefinition, original: Resource = null) -> void:
	catalog = content
	rules = run_rules
	source = original
	owner_input.clear()
	for character in catalog.characters:
		if character != null:
			owner_input.add_item("Propietario: " + character.display_name)
			owner_input.set_item_metadata(owner_input.item_count - 1, character.id)
	type_input.disabled = source != null
	if source != null:
		type_input.select(KINDS.find(Factory.kind_of(source)))
		id_input.text = source.id.substr(0, 38) + "_copia"
		title_input.text = source.display_name + " (copia)"
		if source is RpgCardDefinition:
			for i in range(owner_input.item_count):
				if owner_input.get_item_metadata(i) == source.owner: owner_input.select(i)
	else:
		type_input.select(0)
		id_input.text = ""
		title_input.text = ""
	activate.button_pressed = rules.reward_table == null
	activate.disabled = rules.reward_table == null
	_preview()
	DialogLayout.open(self, Vector2i(660, 620))
	id_input.grab_focus()

func _proposal() -> Dictionary:
	var owner := str(owner_input.get_item_metadata(owner_input.selected)) if owner_input.selected >= 0 else ""
	return Factory.plan(KINDS[type_input.selected], id_input.text, title_input.text, catalog, rules, source, owner, activate.button_pressed)

func _preview() -> void:
	if catalog == null or rules == null: return
	owner_input.visible = KINDS[type_input.selected] == "card"
	activate.visible = KINDS[type_input.selected] == "reward"
	var proposal := _proposal()
	get_ok_button().disabled = not proposal.errors.is_empty()
	if not proposal.errors.is_empty():
		details.text = "\n".join(proposal.errors)
		return
	var lines: Array[String] = []
	for file in proposal.files: lines.append(file.path)
	details.text = "Se crearán estos archivos, sin sobrescribir existentes:\n" + "\n".join(lines) + "\n\nEl registro puede deshacerse. Guarda catálogo y reglas para conservarlo."
	if KINDS[type_input.selected] == "reward" and proposal.rules.reward_table != proposal.resource:
		details.text += "\nLa tabla se guarda sin activarla: asígnala a Reward Table cuando quieras usarla."

func _create() -> void:
	var proposal := _proposal()
	if not proposal.errors.is_empty():
		_preview()
		return
	var error := Factory.persist_new(proposal)
	if error != "":
		details.text = error
		return
	resource_created.emit(proposal)
	hide()
