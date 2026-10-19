@tool
extends RefCounted

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
	return errors

static func _identity(value: Dictionary) -> bool:
	return value.get("id") is String and not str(value.get("id", "")).strip_edges().is_empty() and value.get("name") is String and not str(value.get("name", "")).strip_edges().is_empty()

static func _range(value, minimum: int, maximum: int) -> bool:
	return Values._integer(value) and value >= minimum and value <= maximum
