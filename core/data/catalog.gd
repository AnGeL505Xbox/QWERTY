extends RefCounted

static func load_content() -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/content.json"))
	assert(parsed is Dictionary, "Contenido JSON inválido")
	assert(parsed.version == 1)
	var ids: Dictionary = {}
	for card in parsed.cards:
		assert(not ids.has(card.id), "ID de carta duplicado")
		assert(card.cost >= 0 and not card.effects.is_empty())
		ids[card.id] = true
		for effect in card.effects:
			assert(effect.type in ["damage", "block", "heal"] and effect.amount >= 0)
	for id in parsed.starter_deck:
		assert(ids.has(id), "Referencia de carta desconocida")
	assert(parsed.characters[0].health > 0 and parsed.enemies[0].health > 0)
	assert(parsed.balance.energy > 0 and parsed.balance.hand_size > 0)
	return parsed
