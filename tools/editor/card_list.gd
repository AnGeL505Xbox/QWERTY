@tool
extends ItemList

signal card_dropped(card: RpgCardDefinition, from_index: int, to_index: int)
var cards: Array[RpgCardDefinition] = []
var accepts_cards := false
var owner_id := ""

func _get_drag_data(at_position: Vector2):
	var index := get_item_at_position(at_position, true)
	if index < 0 or index >= cards.size() or cards[index] == null: return null
	var preview := Label.new()
	preview.text = cards[index].display_name
	set_drag_preview(preview)
	return {"type": "rpg_deck_card", "card": cards[index], "source": self, "index": index}

func _can_drop_data(_at_position: Vector2, data) -> bool:
	return accepts_cards and data is Dictionary and data.get("type") == "rpg_deck_card" and data.get("card") is RpgCardDefinition and data.card.owner == owner_id

func _drop_data(at_position: Vector2, data) -> void:
	if not _can_drop_data(at_position, data): return
	var index := get_item_at_position(at_position, true)
	if index < 0: index = cards.size()
	card_dropped.emit(data.card, data.index if data.source == self else -1, index)
