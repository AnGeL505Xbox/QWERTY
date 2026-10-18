@tool
extends RefCounted

const Effects = preload("res://core/effects/registry.gd")

static func validate(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if data.get("version") != 2:
		errors.append("Versión de contenido no compatible (se requiere 2).")
	for key in ["characters", "cards", "enemies", "team"]:
		if not data.get(key) is Array:
			errors.append("Falta la lista: " + key)
	if not errors.is_empty():
		return errors
	var characters := _index(data.characters, "Personaje", errors)
	var cards := _index(data.cards, "Carta", errors)
	_index(data.enemies, "Enemigo", errors)
	var statuses: Dictionary = data.get("statuses", {})
	for id in statuses:
		var state = statuses[id]
		if not state is Dictionary:
			errors.append("Estado inválido: " + str(id))
			continue
		for stat in state:
			if not stat in ["name", "attack", "defense"]:
				errors.append("Modificador desconocido: " + str(stat))
			elif stat != "name" and not _integer(state[stat]):
				errors.append("Modificador no entero: " + str(id))
	if data.team.is_empty() or data.team.size() > 3:
		errors.append("Selecciona de uno a tres personajes en Team.")
	var selected: Array = []
	for id in data.team:
		if not characters.has(id) or id in selected:
			errors.append("Integrante desconocido o repetido: " + str(id))
		selected.append(id)
	for character in data.characters:
		if not character is Dictionary or not character.has("id"):
			continue
		var prefix := "Personaje " + str(character.id) + ": "
		if character.id in ["self", "ally", "enemy"]:
			errors.append(prefix + "ID reservado.")
		for stat in ["health", "energy", "stress_limit"]:
			if not _positive(character.get(stat)):
				errors.append(prefix + stat + " debe ser entero positivo.")
		for stat in ["attack", "defense"]:
			if not _nonnegative(character.get(stat)):
				errors.append(prefix + stat + " debe ser entero no negativo.")
		var crisis: Dictionary = character.get("crisis", {})
		if not _nonnegative(crisis.get("energy_loss")) or not _positive(crisis.get("relief")):
			errors.append(prefix + "configuración de crisis inválida.")
		var passive: Dictionary = character.get("passive", {})
		for value in passive.values():
			if not _nonnegative(value):
				errors.append(prefix + "pasiva inválida.")
		var deck: Array = character.get("deck", [])
		if deck.is_empty():
			errors.append(prefix + "mazo vacío.")
		for id in deck:
			if not cards.has(id) or cards[id].get("owner") != character.id:
				errors.append(prefix + "carta ajena o desconocida en mazo: " + str(id))
		var special = character.get("special", "")
		if not cards.has(special) or cards[special].get("owner") != character.id:
			errors.append(prefix + "habilidad especial ajena o desconocida.")
	for card in data.cards:
		if not card is Dictionary or not card.has("id"):
			continue
		var prefix := "Carta " + str(card.id) + ": "
		if not characters.has(card.get("owner", "")):
			errors.append(prefix + "propietario desconocido.")
		if not _nonnegative(card.get("cost")):
			errors.append(prefix + "coste inválido.")
		if not card.get("target") in ["enemy", "self", "ally"] or not card.get("exhaust") is bool:
			errors.append(prefix + "destino o agotamiento inválido.")
		var effects: Array = card.get("effects", [])
		if effects.is_empty():
			errors.append(prefix + "sin efectos.")
		for effect in effects:
			if not effect is Dictionary or not Effects.valid(effect, str(card.get("target", ""))):
				errors.append(prefix + "efecto incompatible o inválido.")
			elif effect.type == "status" and not statuses.has(effect.get("status", "")):
				errors.append(prefix + "estado desconocido.")
	for enemy in data.enemies:
		if not enemy is Dictionary or not enemy.has("id"):
			continue
		var prefix := "Enemigo " + str(enemy.id) + ": "
		if not _positive(enemy.get("health")):
			errors.append(prefix + "vida inválida.")
		var pattern: Array = enemy.get("pattern", [])
		if pattern.is_empty():
			errors.append(prefix + "patrón vacío.")
		for intent in pattern:
			if not intent is Dictionary or not intent.get("type") in ["attack", "guard", "heal"] or not _nonnegative(intent.get("amount")):
				errors.append(prefix + "intención inválida.")
	if not _positive(data.get("balance", {}).get("hand_size")):
		errors.append("Hand Size debe ser entero positivo.")
	return errors

static func _index(values: Array, title: String, errors: PackedStringArray) -> Dictionary:
	var result: Dictionary = {}
	if values.is_empty():
		errors.append(title + ": lista vacía.")
	for item in values:
		if not item is Dictionary or not item.get("id") is String or str(item.get("id", "")).strip_edges().is_empty():
			errors.append(title + ": entrada nula o sin ID.")
			continue
		if not item.get("name") is String or str(item.get("name", "")).strip_edges().is_empty():
			errors.append(title + ": nombre vacío en " + str(item.id))
		if result.has(item.id):
			errors.append(title + ": ID repetido " + item.id)
		result[item.id] = item
	return result

static func _integer(value) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value == int(value)

static func _positive(value) -> bool:
	return _integer(value) and value > 0

static func _nonnegative(value) -> bool:
	return _integer(value) and value >= 0
