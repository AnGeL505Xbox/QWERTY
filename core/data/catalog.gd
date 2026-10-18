extends RefCounted

const Effects = preload("res://core/effects/registry.gd")

static func load_content() -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/content.json"))
	assert(parsed is Dictionary, "Contenido JSON inválido")
	assert(parsed.version == 1)
	var ids: Dictionary = {}
	for card in parsed.cards:
		assert(not ids.has(card.id), "ID de carta duplicado")
		assert(card.cost >= 0 and not card.effects.is_empty())
		assert(card.target in ["self", "enemy"] and card.exhaust is bool)
		ids[card.id] = true
		for effect in card.effects:
			assert(Effects.valid(effect, card.target), "Efecto o destino inválido")
	for id in parsed.starter_deck:
		assert(ids.has(id), "Referencia de carta desconocida")
	assert(parsed.characters[0].health > 0)
	var enemy_ids: Dictionary = {}
	for enemy in parsed.enemies:
		assert(not enemy_ids.has(enemy.id) and enemy.health > 0)
		enemy_ids[enemy.id] = true
		assert(not enemy.pattern.is_empty())
		for intent in enemy.pattern:
			assert(intent.type in ["attack", "guard", "heal"] and intent.amount >= 0)
	assert(parsed.balance.energy > 0 and parsed.balance.hand_size > 0)
	return parsed
