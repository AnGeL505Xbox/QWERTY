extends RefCounted

const Effects = preload("res://core/effects/registry.gd")

static func load_content() -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/content.json"))
	assert(parsed is Dictionary, "Contenido JSON inválido")
	assert(parsed.version == 2)
	for status in parsed.statuses.values():
		assert(status.name is String)
		for key in status:
			assert(key in ["name", "attack", "defense"], "Modificador no implementado")
			if key != "name":
				assert(status[key] is int or status[key] is float)
				assert(status[key] == int(status[key]))
	var ids: Dictionary = {}
	var character_ids: Dictionary = {}
	for character in parsed.characters:
		assert(not character_ids.has(character.id))
		character_ids[character.id] = true
		for stat in ["health", "energy", "stress_limit"]:
			assert(character[stat] > 0)
		assert(character.attack >= 0 and character.defense >= 0)
		assert(character.crisis.energy_loss >= 0 and character.crisis.relief > 0)
		assert(character.passive.get("start_block", 0) >= 0 and character.passive.get("stress_relief", 0) >= 0)
	assert(parsed.team.size() >= 1 and parsed.team.size() <= 3)
	var team_ids: Dictionary = {}
	for id in parsed.team:
		assert(character_ids.has(id) and not team_ids.has(id))
		team_ids[id] = true
	for card in parsed.cards:
		assert(not ids.has(card.id), "ID de carta duplicado")
		assert(card.cost >= 0 and not card.effects.is_empty())
		assert(card.target in ["self", "enemy", "ally"] and card.exhaust is bool)
		assert(character_ids.has(card.owner), "Propietario desconocido")
		ids[card.id] = card.owner
		for effect in card.effects:
			assert(Effects.valid(effect, card.target), "Efecto o destino inválido")
			if effect.type == "status":
				assert(parsed.statuses.has(effect.status), "Estado desconocido")
	for character in parsed.characters:
		assert(not character.deck.is_empty())
		for id in character.deck:
			assert(ids.has(id) and ids[id] == character.id, "Carta ajena o desconocida en mazo")
		assert(ids.has(character.special) and ids[character.special] == character.id)
	var enemy_ids: Dictionary = {}
	for enemy in parsed.enemies:
		assert(not enemy_ids.has(enemy.id) and enemy.health > 0)
		enemy_ids[enemy.id] = true
		assert(not enemy.pattern.is_empty())
		for intent in enemy.pattern:
			assert(intent.type in ["attack", "guard", "heal"] and intent.amount >= 0)
	assert(parsed.balance.hand_size > 0)
	return parsed
