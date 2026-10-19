@tool
extends RefCounted
const Values = preload("res://core/data/validator.gd")

static func validate(config: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	for group in ["relics", "biomes"]:
		if not config.has(group): continue
		var entries = config[group]
		if not entries is Array or entries.is_empty() or entries.size() > 32:
			errors.append("Expansión: " + group + " debe contener entre 1 y 32 entradas.")
			continue
		var ids: Array = []
		for entry in entries:
			if not entry is Dictionary or not entry.get("id") is String or str(entry.get("id", "")).strip_edges() == "" or not entry.get("name") is String or str(entry.get("name", "")).strip_edges() == "" or not entry.get("description") is String:
				errors.append("Expansión: entrada inválida en " + group)
				continue
			var prefix: String = ("Reliquia " if group == "relics" else "Bioma ") + entry.id + ": "
			if entry.id in ids: errors.append(prefix + "ID repetido.")
			ids.append(entry.id)
			if group == "relics":
				for field in {"turn_block": 10, "turn_energy": 2, "victory_heal": 10, "victory_gold": 30}:
					if not _range(entry.get(field), 0, {"turn_block": 10, "turn_energy": 2, "victory_heal": 10, "victory_gold": 30}[field]): errors.append(prefix + field + " fuera de rango.")
			else:
				if not _range(config.get("rows"), 4, 8) or not _range(entry.get("first_row"), 0, int(config.get("rows", 0)) - 1) or not _range(entry.get("last_row"), int(entry.get("first_row", 0)) if Values._integer(entry.get("first_row")) else 0, int(config.get("rows", 0)) - 1):
					errors.append(prefix + "rango de etapas inválido.")
				if not entry.get("color") is String or not Color.html_is_valid(entry.get("color", "")): errors.append(prefix + "color inválido.")
				for field in ["encounters", "events"]:
					var allowed: Array = config.get("encounters", []) if field == "encounters" and config.get("encounters") is Array else []
					if field == "events" and config.get("events") is Array:
						for event in config.events:
							if event is Dictionary and event.get("id") is String: allowed.append(event.id)
					if not entry.get(field) is Array:
						errors.append(prefix + field + " debe ser una lista.")
						continue
					var seen: Array = []
					for id in entry[field]:
						if not id is String or not id in allowed or id in seen: errors.append(prefix + "referencia desconocida o repetida en " + field)
						seen.append(id)
	if errors.is_empty() and config.has("biomes"):
		for row in range(int(config.rows)):
			var matching: Array = config.biomes.filter(func(biome): return row >= biome.first_row and row <= biome.last_row)
			if matching.size() != 1: errors.append("Biomas: cada etapa debe pertenecer a un único bioma (etapa %d)." % (row + 1))
		if config.get("route_nodes") is Array:
			for node in config.route_nodes:
				if not node is Dictionary or not Values._integer(node.get("row")) or not node.get("enemy") is String: continue
				var biome := biome_for_row(config, int(node.row))
				if node.get("type") != "boss" and node.enemy != "" and not biome.get("encounters", []).is_empty() and not node.enemy in biome.encounters:
					errors.append("Bioma " + str(biome.get("id", "")) + ": enemigo fijado fuera de su pool.")
	return errors

static func biome_for_row(config: Dictionary, row: int) -> Dictionary:
	if not config.get("biomes", []) is Array: return {}
	for biome in config.get("biomes", []):
		if not biome is Dictionary or not Values._integer(biome.get("first_row")) or not Values._integer(biome.get("last_row")): continue
		if row >= int(biome.first_row) and row <= int(biome.last_row): return biome
	return {}

static func _range(value, minimum: int, maximum: int) -> bool:
	return Values._integer(value) and value >= minimum and value <= maximum
