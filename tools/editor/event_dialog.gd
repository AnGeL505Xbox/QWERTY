@tool
extends "res://tools/editor/edit_dialog.gd"

const Editing = preload("res://tools/editor/editing.gd")
var catalog: RpgContentCatalog
var rules: RpgRunDefinition
var target: RpgEventDefinition
var draft: RpgEventDefinition
var id_input: LineEdit
var name_input: LineEdit
var description_input: TextEdit
var choices: ItemList
var choice_id: LineEdit
var choice_label: LineEdit
var gold: SpinBox
var health: SpinBox
var stress: SpinBox
var gift: OptionButton
var effect_summary: Label
var choice_form: VBoxContainer
var selected := -1
var loading := false

func build() -> void:
	title = "Editor de eventos"
	note("Edita el texto y las decisiones. Oro/PV/estrés admiten cambios positivos o negativos. Aplicar valida el borrador completo; Cancelar conserva el evento anterior.")
	var identity := HBoxContainer.new()
	form.add_child(identity)
	id_input = line(identity, "ID del evento")
	name_input = line(identity, "Nombre visible")
	description_input = TextEdit.new()
	description_input.custom_minimum_size.y = 85
	description_input.placeholder_text = "Descripción que verá el jugador"
	form.add_child(description_input)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	form.add_child(columns)
	var left := VBoxContainer.new()
	columns.add_child(left)
	choices = ItemList.new()
	choices.custom_minimum_size = Vector2(260, 230)
	choices.size_flags_vertical = Control.SIZE_EXPAND_FILL
	choices.item_selected.connect(_select)
	left.add_child(choices)
	var actions := HBoxContainer.new()
	left.add_child(actions)
	button(actions, "+ Opción", _add)
	button(actions, "Quitar", _remove)
	button(actions, "↑", func(): _move(-1))
	button(actions, "↓", func(): _move(1))
	choice_form = VBoxContainer.new()
	choice_form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(choice_form)
	choice_id = line(choice_form, "ID de la opción")
	choice_label = line(choice_form, "Texto del botón")
	var amounts := HBoxContainer.new()
	choice_form.add_child(amounts)
	gold = spin(amounts, "Oro", -999, 999)
	health = spin(amounts, "PV (equipo vivo)", -999, 999)
	stress = spin(amounts, "Estrés", -999, 999)
	gift = OptionButton.new()
	choice_form.add_child(gift)
	for input in [choice_id, choice_label]: input.text_changed.connect(func(_value): _write_choice())
	for input in [gold, health, stress]: input.value_changed.connect(func(_value): _write_choice())
	gift.item_selected.connect(func(_index): _write_choice())
	effect_summary = Label.new()
	effect_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choice_form.add_child(effect_summary)

func open_for(content: RpgContentCatalog, run_rules: RpgRunDefinition, event: RpgEventDefinition) -> void:
	catalog = content
	rules = run_rules
	target = event
	draft = Editing.event_draft(event)
	title = "Evento · " + event.display_name
	id_input.text = draft.id
	name_input.text = draft.display_name
	description_input.text = draft.description
	gift.clear()
	gift.add_item("Sin carta de regalo")
	gift.set_item_metadata(0, null)
	for card in catalog.cards:
		if card == null: continue
		gift.add_item("Carta: %s (%s)" % [card.display_name, card.owner])
		gift.set_item_metadata(gift.item_count - 1, card)
	report.text = "Borrador sin aplicar. Las opciones se muestran en su orden de lista."
	_refresh(0 if not draft.choices.is_empty() else -1)
	DialogLayout.open(self)

func _refresh(index: int) -> void:
	choices.clear()
	for choice in draft.choices: choices.add_item(choice.label if choice != null else "Opción nula: quitar")
	selected = -1
	choice_form.visible = false
	if index >= 0 and index < draft.choices.size():
		choices.select(index)
		_select(index)

func _select(index: int) -> void:
	selected = index
	var choice := draft.choices[index]
	choice_form.visible = choice != null
	if choice == null: return
	loading = true
	choice_id.text = choice.id
	choice_label.text = choice.label
	gold.value = choice.gold_delta
	health.value = choice.health_delta
	stress.value = choice.stress_delta
	gift.select(0)
	for i in range(gift.item_count):
		if gift.get_item_metadata(i) == choice.card: gift.select(i)
	loading = false
	_write_choice()

func _write_choice() -> void:
	if loading or draft == null or selected < 0 or selected >= draft.choices.size(): return
	var choice := draft.choices[selected]
	if choice == null: return
	choice.id = choice_id.text.strip_edges()
	choice.label = choice_label.text
	choice.gold_delta = int(gold.value)
	choice.health_delta = int(health.value)
	choice.stress_delta = int(stress.value)
	choice.card = gift.get_item_metadata(gift.selected) if gift.selected >= 0 else null
	choices.set_item_text(selected, choice.label)
	effect_summary.text = "Oro %+d · PV %+d · Estrés %+d\nEl daño añade estrés. La curación no revive. Las opciones con coste requieren oro; una carta requiere a su propietario en el equipo." % [choice.gold_delta, choice.health_delta, choice.stress_delta]

func _add() -> void:
	if draft.choices.size() >= 8:
		report.text = "Máximo de ocho decisiones por evento."
		return
	var choice := RpgEventChoice.new()
	var suffix := 1
	var ids := draft.choices.map(func(entry): return entry.id if entry != null else "")
	while "opcion_" + str(suffix) in ids: suffix += 1
	choice.id = "opcion_" + str(suffix)
	draft.choices.append(choice)
	_refresh(draft.choices.size() - 1)

func _remove() -> void:
	if selected < 0: return
	draft.choices.remove_at(selected)
	_refresh(mini(selected, draft.choices.size() - 1))

func _move(offset: int) -> void:
	var next := selected + offset
	if selected < 0 or next < 0 or next >= draft.choices.size(): return
	var choice := draft.choices[selected]
	draft.choices.remove_at(selected)
	draft.choices.insert(next, choice)
	_refresh(next)

func submit() -> void:
	_write_choice()
	draft.id = id_input.text.strip_edges()
	draft.display_name = name_input.text
	draft.description = description_input.text
	publish(Editing.event_proposal(catalog, rules, target, draft))
