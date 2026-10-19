extends RefCounted

const ContentValidator = preload("res://core/data/validator.gd")
const Progression = preload("res://core/data/progression_validator.gd")
const Route = preload("res://core/progression/route.gd")

static func configuration(content: Dictionary, config: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if not _integer(config.get("rows"), 4, 8):
		errors.append("El recorrido requiere entre 4 y 8 etapas.")
	if not config.get("encounters") is Array or config.get("encounters", []).is_empty():
		errors.append("Faltan enemigos para los encuentros.")
	else:
		var enemy_ids: Array = content.enemies.map(func(enemy): return enemy.id)
		for id in config.encounters:
			if not id in enemy_ids:
				errors.append("Encuentro desconocido: " + str(id))
	if not config.get("boss") is Dictionary or not config.get("boss", {}).has("id"):
		errors.append("Falta un jefe válido.")
	else:
		var combined := content.duplicate(true)
		combined.enemies = combined.enemies.filter(func(enemy): return enemy.id != config.boss.id)
		combined.enemies.append(config.boss)
		if _content_shape(combined):
			errors.append_array(ContentValidator.validate(combined))
		else:
			errors.append("Definición de jefe incompleta.")
	if not config.get("middle_types") is Array or config.get("middle_types", []).is_empty():
		errors.append("Faltan tipos de nodo intermedios.")
	else:
		for type in config.middle_types:
			if not type in ["combat", "event", "reward", "rest", "shop"]:
				errors.append("Tipo de nodo desconocido.")
	for key in ["starting_gold", "combat_gold", "elite_gold_bonus", "rest_heal", "stress_relief", "card_price", "upgrade_price", "event_gold", "event_damage", "elite_health_bonus", "elite_damage_bonus"]:
		if not _integer(config.get(key), 1 if key in ["card_price", "upgrade_price", "rest_heal"] else 0, 9999):
			errors.append("Valor de expedición inválido: " + key)
	if not _integer(config.get("max_upgrade_level"), 1, 5) or not _integer(config.get("upgrade_amount"), 1, 9):
		errors.append("Reglas de mejora inválidas.")
	errors.append_array(Progression.validate(content, config))
	return errors

static func validate(saved: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	for key in ["content", "config", "party", "upgrades", "battle"]:
		if not saved.get(key) is Dictionary:
			errors.append("Falta el objeto de guardado: " + key)
	for key in ["team", "nodes", "visited", "offers"]:
		if not saved.get(key) is Array:
			errors.append("Falta la lista de guardado: " + key)
	if not _rng_integer(saved.get("seed")) or not _rng_integer(saved.get("rng_state")):
		errors.append("Semilla o generador inválido.")
	if not saved.get("phase") in ["map", "combat", "reward", "rest", "shop", "event", "victory", "defeat"] or not saved.get("current") is String:
		errors.append("Fase o posición inválida.")
	if not _integer(saved.get("gold"), 0, 9999999):
		errors.append("Oro inválido.")
	if not errors.is_empty():
		return errors
	if not _content_shape(saved.content):
		return PackedStringArray(["La estructura del catálogo guardado es inválida."])
	errors.append_array(ContentValidator.validate(saved.content))
	if not errors.is_empty():
		return errors
	errors.append_array(configuration(saved.content, saved.config))
	if not errors.is_empty():
		return errors
	var expected := Route.generate(int(saved.seed), saved.config)
	if _canonical(saved.nodes) != _canonical(expected):
		errors.append("El mapa no corresponde a su semilla y configuración.")
		return errors
	var indexed: Dictionary = {}
	for node in saved.nodes:
		indexed[node.id] = node
	var previous := ""
	var used: Array = []
	for id in saved.visited:
		if not id is String or not indexed.has(id) or id in used:
			errors.append("Historial de ruta inválido.")
			return errors
		if (previous == "" and indexed[id].row != 0) or (previous != "" and not id in indexed[previous].links):
			errors.append("La ruta visitada no está conectada.")
		previous = id
		used.append(id)
	if saved.current != "" and not indexed.has(saved.current):
		errors.append("Nodo actual desconocido.")
		return errors
	if saved.phase == "map":
		if saved.current != previous:
			errors.append("Posición de mapa incoherente.")
	elif saved.phase == "victory":
		if saved.current == "" or saved.current != previous or indexed[saved.current].type != "boss":
			errors.append("Victoria sin completar el jefe.")
	else:
		if saved.current == "":
			errors.append("Falta el nodo activo.")
		elif saved.current != previous and ((previous == "" and indexed[saved.current].row != 0) or (previous != "" and not saved.current in indexed[previous].links)):
			errors.append("Nodo activo inaccesible.")
		elif saved.phase != "defeat" and saved.current in used:
			errors.append("Nodo activo ya completado.")
		elif saved.phase == "combat" and not indexed[saved.current].type in ["combat", "elite", "boss"]:
			errors.append("Combate en un nodo incompatible.")
		elif saved.phase in ["shop", "rest", "event"] and indexed[saved.current].type != saved.phase:
			errors.append("Fase incompatible con el nodo.")
	var definitions: Dictionary = {}
	for character in saved.content.characters:
		definitions[character.id] = character
	if saved.team.is_empty() or saved.team.size() > 3 or saved.party.size() != saved.team.size():
		errors.append("Equipo guardado inválido.")
	var team: Array = []
	for id in saved.team:
		if not definitions.has(id) or id in team or not saved.party.get(id) is Dictionary:
			errors.append("Integrante guardado inválido.")
			continue
		team.append(id)
		var member: Dictionary = saved.party[id]
		if not _integer(member.get("health"), 0, int(definitions[id].health)) or not _integer(member.get("stress"), 0, int(definitions[id].stress_limit)):
			errors.append("Vida o estrés fuera de rango: " + str(id))
	if not errors.is_empty():
		return errors
	var living: bool = saved.party.values().any(func(member): return member.health > 0)
	if not living and not (saved.phase == "defeat" or (saved.phase == "combat" and saved.battle.get("result") == "Derrota")):
		errors.append("No quedan integrantes vivos en una partida activa.")
	if living and saved.phase == "defeat":
		errors.append("Derrota incoherente con la vida del equipo.")
	var cards: Dictionary = {}
	for card in saved.content.cards:
		cards[card.id] = card
	var owned: Array = []
	for id in saved.team:
		owned.append_array(definitions[id].deck)
	for id in saved.upgrades:
		if not id in owned or not cards.has(id) or not cards[id].owner in saved.team or not _integer(saved.upgrades[id], 1, int(saved.config.max_upgrade_level)):
			errors.append("Mejora guardada inválida.")
	if saved.offers.size() > (11 if saved.config.has("rewards") else 6):
		errors.append("Demasiadas recompensas guardadas.")
	var offer_ids: Array = []
	for offer in saved.offers:
		if not offer is Dictionary or not offer.get("action") in ["card", "upgrade", "skip"] or not offer.get("id") is String:
			errors.append("Oferta guardada inválida.")
			continue
		var key: String = offer.action + ":" + offer.id
		if key in offer_ids:
			errors.append("Oferta duplicada.")
		offer_ids.append(key)
		if offer.action != "skip" and (not cards.has(offer.id) or not cards[offer.id].owner in saved.team):
			errors.append("Carta de recompensa desconocida o ajena.")
		if saved.phase == "shop" and offer.action != "card":
			errors.append("Oferta de tienda inválida.")
	if not saved.phase in ["reward", "shop"] and not saved.offers.is_empty():
		errors.append("Ofertas fuera de su fase.")
	if saved.phase == "reward" and saved.offers.is_empty():
		errors.append("Recompensa sin opciones.")
	if saved.phase == "combat" and errors.is_empty():
		errors.append_array(_battle(saved, definitions, cards))
	elif saved.phase != "combat" and not saved.battle.is_empty():
		errors.append("Combate guardado fuera de fase.")
	if saved.config.has("events"):
		var event_id = saved.get("event_id", "")
		if not event_id is String or (saved.phase == "event" and not saved.config.events.any(func(event): return event.id == event_id)):
			errors.append("Evento activo desconocido.")
	return errors

static func _battle(run: Dictionary, definitions: Dictionary, cards: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var state: Dictionary = run.battle
	for field in ["hand", "draw", "discard", "exhausted"]:
		if not state.get(field) is Array:
			errors.append("Pila de cartas inválida.")
	if not state.get("members") is Dictionary or not state.get("intent") is Dictionary:
		errors.append("Estado de combate incompleto.")
	if not _rng_integer(state.get("rng_seed")) or not _rng_integer(state.get("rng_state")) or not _integer(state.get("turn"), 1, 1000000):
		errors.append("Turno o RNG de combate inválido.")
	if not errors.is_empty():
		return errors
	var current: Dictionary = run.nodes.filter(func(node): return node.id == run.current)[0]
	var enemies: Array = run.content.enemies.filter(func(enemy): return enemy.id == state.get("enemy"))
	if enemies.size() != 1 or state.enemy != current.enemy:
		return PackedStringArray(["Enemigo guardado desconocido."])
	var enemy: Dictionary = enemies[0]
	var bonus := int(run.config.elite_health_bonus) if current.type == "elite" else 0
	if not _integer(state.get("enemy_health"), 0, int(enemy.health) + bonus) or not _integer(state.get("enemy_block"), 0, 1000000):
		errors.append("Estadísticas enemigas inválidas.")
	var expected: Dictionary = enemy.pattern[(int(state.turn) - 1) % enemy.pattern.size()].duplicate()
	if current.type == "elite" and expected.type == "attack":
		expected.amount = int(expected.amount) + int(run.config.elite_damage_bonus)
	if state.intent.get("type") != expected.type or state.intent.get("amount") != expected.amount or not state.intent.get("target") in run.team:
		errors.append("Intención enemiga incoherente.")
	var counts: Dictionary = {}
	for id in run.team:
		for card_id in definitions[id].deck:
			counts[card_id] = int(counts.get(card_id, 0)) + 1
	for field in ["hand", "draw", "discard", "exhausted"]:
		for id in state[field]:
			if not id is String or not cards.has(id):
				errors.append("Carta desconocida en combate.")
			else:
				counts[id] = int(counts.get(id, 0)) - 1
	if counts.values().any(func(count): return count != 0):
		errors.append("Las pilas no conservan las cartas del mazo.")
	if state.members.size() != run.team.size():
		errors.append("Equipo de combate incompleto.")
	var alive := false
	for id in run.team:
		if not state.members.get(id) is Dictionary:
			errors.append("Falta un combatiente.")
			continue
		var member: Dictionary = state.members[id]
		if member.get("health") != run.party[id].health or member.get("stress") != run.party[id].stress:
			errors.append("El combate y el equipo tienen vidas diferentes.")
		alive = alive or run.party[id].health > 0
		if not _integer(member.get("energy"), 0, 1000000) or not _integer(member.get("block"), 0, 1000000) or not member.get("crisis") is bool or not member.get("statuses") is Dictionary:
			errors.append("Estado individual inválido.")
		else:
			for status in member.statuses:
				if not run.content.statuses.has(status) or not _integer(member.statuses[status], 1, 999):
					errors.append("Estado temporal inválido.")
	var result := "Victoria" if state.get("enemy_health") == 0 else ("" if alive else "Derrota")
	if state.get("result") != result:
		errors.append("Resultado de combate incoherente.")
	return errors

static func _integer(value, minimum: int, maximum: int) -> bool:
	return ContentValidator._integer(value) and value >= minimum and value <= maximum

static func _rng_integer(value) -> bool:
	return value is String and value.length() <= 20 and value.is_valid_int() and str(int(value)) == value

static func _canonical(value):
	return JSON.parse_string(JSON.stringify(value))

static func _content_shape(data: Dictionary) -> bool:
	for key in ["characters", "cards", "enemies", "team"]:
		if not data.get(key) is Array:
			return false
	if not data.get("statuses") is Dictionary or not data.get("balance") is Dictionary:
		return false
	for definition in data.characters:
		if not definition is Dictionary or not definition.get("crisis") is Dictionary or not definition.get("passive") is Dictionary or not definition.get("deck") is Array:
			return false
	for definition in data.cards:
		if not definition is Dictionary or not definition.get("effects") is Array:
			return false
		for effect in definition.effects:
			if not effect is Dictionary:
				return false
	for definition in data.enemies:
		if not definition is Dictionary or not definition.get("pattern") is Array:
			return false
		for intent in definition.pattern:
			if not intent is Dictionary:
				return false
	return true

static func resource_configuration(catalog: RpgContentCatalog, rules: RpgRunDefinition) -> PackedStringArray:
	if catalog == null or rules == null:
		return PackedStringArray(["Falta el catálogo o la configuración de expedición."])
	var errors := configuration(catalog.to_dict(), rules.to_dict())
	if rules.reward_table != null:
		for card in rules.reward_table.cards:
			if card != null and not card in catalog.cards:
				errors.append("Recompensas: usa el mismo recurso registrado en Cards.")
	for event in rules.events:
		if event != null:
			for choice in event.choices:
				if choice != null and choice.card != null and not choice.card in catalog.cards:
					errors.append("Evento " + event.id + ": carta no registrada con el mismo recurso.")
	for node in rules.route_nodes:
		if node != null and node.enemy != null and not node.enemy in rules.encounters:
			errors.append("Ruta: enemigo no registrado con el mismo recurso en Encounters.")
	for enemy in rules.encounters:
		if enemy != null and not enemy in catalog.enemies:
			errors.append("Encuentro " + enemy.id + ": usa el mismo recurso registrado en Enemies del catálogo.")
	return errors
