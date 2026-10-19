@tool
extends RefCounted

const Expansion = preload("res://core/data/expansion_validator.gd")
const Values = preload("res://core/data/validator.gd")

static func validate(content: Dictionary, config: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var cards: Dictionary = {}
	for card in content.cards:
		cards[card.id] = true
	if config.has("rewards"):
		var table = config.rewards
		if not table is Dictionary:
			errors.append("Recompensas: tabla inválida.")
		else:
			if not _identity(table):
				errors.append("Recompensas: faltan ID o nombre.")
			for key in ["card_choices", "upgrade_choices"]:
				if not _range(table.get(key), 0, 5):
					errors.append("Recompensas: " + key + " debe estar entre 0 y 5.")
			if not table.get("allow_skip") is bool or not table.get("pool") is Array:
				errors.append("Recompensas: opciones o pool inválidos.")
			else:
				var seen: Array = []
				for id in table.pool:
					if not id is String or not cards.has(id) or id in seen:
						errors.append("Recompensas: carta desconocida o repetida: " + str(id))
					seen.append(id)
	if config.has("events"):
		if not config.events is Array or config.events.is_empty():
			errors.append("Eventos: lista inválida o vacía.")
			return errors
		var ids: Array = []
		for event in config.events:
			if not event is Dictionary or not _identity(event):
				errors.append("Evento: entrada nula, sin ID o sin nombre.")
				continue
			var prefix: String = "Evento " + event.id + ": "
			if event.id in ids:
				errors.append(prefix + "ID repetido.")
			ids.append(event.id)
			if not event.get("description") is String or not event.get("choices") is Array or event.get("choices", []).is_empty() or event.get("choices", []).size() > 8:
				errors.append(prefix + "requiere descripción y de 1 a 8 opciones.")
				continue
			var choices: Array = []
			for choice in event.choices:
				if not choice is Dictionary or not choice.get("id") is String or str(choice.get("id", "")).is_empty() or not choice.get("label") is String or str(choice.get("label", "")).strip_edges().is_empty():
					errors.append(prefix + "opción nula o sin ID/texto.")
					continue
				if choice.id in choices:
					errors.append(prefix + "opción repetida " + choice.id)
				choices.append(choice.id)
				for key in ["gold", "health", "stress"]:
					if not _range(choice.get(key), -999, 999):
						errors.append(prefix + choice.id + ": magnitud inválida " + key)
				if not choice.get("card") is String or (choice.get("card", "") != "" and not cards.has(choice.card)):
					errors.append(prefix + choice.id + ": carta desconocida.")
	errors.append_array(validate_route(config))
	errors.append_array(Expansion.validate(config))
	return errors

static func _identity(value: Dictionary) -> bool:
	return value.get("id") is String and not str(value.get("id", "")).strip_edges().is_empty() and value.get("name") is String and not str(value.get("name", "")).strip_edges().is_empty()

static func _range(value, minimum: int, maximum: int) -> bool:
	return Values._integer(value) and value >= minimum and value <= maximum

# El formato conserva las coordenadas y contratos del mapa de juego: dos carriles y jefe final.
static func validate_route(config: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if not config.has("route_nodes"): return errors
	var nodes = config.route_nodes
	if not nodes is Array or not _range(config.get("rows"), 4, 8) or nodes.size() != int(config.rows) * 2 - 1:
		return PackedStringArray(["Ruta: requiere dos nodos por etapa y un jefe final (4–8 etapas)."])
	for index in range(nodes.size()):
		var node = nodes[index]
		var row := index / 2
		var column := index % 2
		var id := "%d_%d" % [row, column]
		if not node is Dictionary or node.get("id") != id or not _range(node.get("row"), row, row) or not _range(node.get("column"), column, column):
			errors.append("Ruta: posición/orden inválido en " + id)
			continue
		var last := row == int(config.rows) - 1
		if not node.get("type") in ["combat", "elite", "event", "reward", "rest", "shop", "boss"] or (last != (node.get("type") == "boss")):
			errors.append("Ruta " + id + ": el jefe solo puede estar en la etapa final.")
		if not node.get("enemy") is String or (node.enemy != "" and node.get("type") != "boss" and not node.enemy in config.get("encounters", [])):
			errors.append("Ruta " + id + ": enemigo fuera de Encounters.")
		if not node.get("links") is Array or (last and not node.links.is_empty()) or (not last and node.links.is_empty()):
			errors.append("Ruta " + id + ": conexiones vacías o posteriores al jefe.")
			continue
		var seen: Array = []
		for link in node.links:
			var valid: Array = []
			if not last:
				for next in range(1 if row == int(config.rows) - 2 else 2): valid.append("%d_%d" % [row + 1, next])
			if not link in valid or link in seen: errors.append("Ruta " + id + ": conexión inválida o repetida.")
			seen.append(link)
	if not errors.is_empty(): return errors
	var reachable: Array = ["0_0", "0_1"]
	for node in nodes:
		if not node.id in reachable: errors.append("Ruta " + node.id + ": nodo inaccesible.")
		else:
			for link in node.links:
				if not link in reachable: reachable.append(link)
	return errors
