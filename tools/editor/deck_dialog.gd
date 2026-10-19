@tool
extends "res://tools/editor/edit_dialog.gd"

const Editing = preload("res://tools/editor/editing.gd")
const CardList = preload("res://tools/editor/card_list.gd")
var catalog: RpgContentCatalog
var character: RpgCharacterDefinition
var draft: Array[RpgCardDefinition] = []
var pool: ItemList
var deck: ItemList
var search: LineEdit
var special: OptionButton
var summary: Label

func build() -> void:
	title = "Editor de mazos"
	note("Arrastra cartas del catálogo al mazo o usa Añadir copia. Arrastra dentro del mazo para ordenar. Los cambios se aplican juntos y admiten Deshacer.")
	search = line(form, "Buscar carta del personaje")
	search.text_changed.connect(func(_text): _pool())
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	form.add_child(columns)
	pool = CardList.new()
	pool.custom_minimum_size = Vector2(390, 260)
	pool.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(pool)
	deck = CardList.new()
	deck.accepts_cards = true
	deck.custom_minimum_size = Vector2(390, 260)
	deck.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck.card_dropped.connect(_drop)
	columns.add_child(deck)
	var actions := HBoxContainer.new()
	form.add_child(actions)
	button(actions, "Añadir copia →", _add)
	button(actions, "Quitar copia", _remove)
	button(actions, "Subir", func(): _move(-1))
	button(actions, "Bajar", func(): _move(1))
	special = OptionButton.new()
	form.add_child(special)
	summary = note("")

func open_for(content: RpgContentCatalog, target: RpgCharacterDefinition) -> void:
	catalog = content
	character = target
	draft = character.deck.duplicate()
	title = "Mazo · " + character.display_name
	deck.owner_id = character.id
	search.text = ""
	special.clear()
	for card in catalog.cards:
		if card != null and card.owner == character.id:
			special.add_item("Especial: " + card.display_name + " [" + card.id + "]")
			special.set_item_metadata(special.item_count - 1, card)
			if card == character.special: special.select(special.item_count - 1)
	report.text = "Borrador sin aplicar. Cancelar conserva el mazo anterior."
	_pool()
	_refresh()
	DialogLayout.open(self)

func _pool() -> void:
	if catalog == null: return
	pool.clear()
	pool.cards.clear()
	for card in catalog.cards:
		if card == null or card.owner != character.id: continue
		if not search.text.is_empty() and not (card.id + " " + card.display_name).to_lower().contains(search.text.to_lower()): continue
		pool.cards.append(card)
		pool.add_item("%s · %d energía [%s]" % [card.display_name, card.cost, card.id])
		pool.set_item_tooltip(pool.item_count - 1, card.description)

func _refresh(selected: int = -1) -> void:
	deck.clear()
	deck.cards = draft.duplicate()
	var cost := 0
	var unique: Array = []
	for card in draft:
		deck.add_item("%s · %d energía [%s]" % [card.display_name, card.cost, card.id] if card != null else "Carta nula: quítala")
		if card == null: continue
		cost += card.cost
		if not card in unique: unique.append(card)
	if selected >= 0 and selected < draft.size(): deck.select(selected)
	summary.text = "%d copias · %d cartas distintas · Coste medio %.2f" % [draft.size(), unique.size(), float(cost) / maxi(1, draft.size())]

func _add() -> void:
	if pool.get_selected_items().is_empty(): return
	draft.append(pool.cards[pool.get_selected_items()[0]])
	_refresh(draft.size() - 1)

func _remove() -> void:
	if deck.get_selected_items().is_empty(): return
	var index := deck.get_selected_items()[0]
	draft.remove_at(index)
	_refresh(mini(index, draft.size() - 1))

func _move(offset: int) -> void:
	if deck.get_selected_items().is_empty(): return
	var index := deck.get_selected_items()[0]
	var next := index + offset
	if next < 0 or next >= draft.size(): return
	var card := draft[index]
	draft.remove_at(index)
	draft.insert(next, card)
	_refresh(next)

func _drop(card: RpgCardDefinition, from_index: int, to_index: int) -> void:
	if from_index >= 0:
		draft.remove_at(from_index)
		if to_index > from_index: to_index -= 1
	draft.insert(clampi(to_index, 0, draft.size()), card)
	_refresh(clampi(to_index, 0, draft.size() - 1))

func submit() -> void:
	var selected: RpgCardDefinition = special.get_item_metadata(special.selected) if special.selected >= 0 else null
	publish(Editing.deck_proposal(catalog, character, draft, selected))
