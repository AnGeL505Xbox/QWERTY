@tool
extends RefCounted

const Expansion = preload("res://core/data/expansion_validator.gd")
const Progression = preload("res://core/data/progression_validator.gd")

static func generate(seed_value: int, config: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	if config.has("route_nodes"):
		if not Progression.validate_route(config).is_empty(): return []
		return preview_custom(seed_value, config)
	var nodes: Array = []
	for row in range(int(config.rows)):
		var width := 1 if row == int(config.rows) - 1 else 2
		for column in range(width):
			var kind := "combat"
			if row == int(config.rows) - 1:
				kind = "boss"
			elif row == int(config.rows) - 2:
				kind = "elite" if column == 0 else "combat"
			elif row == int(config.rows) / 2:
				kind = "rest" if column == 0 else "shop"
			elif row > 0:
				kind = config.middle_types[rng.randi_range(0, config.middle_types.size() - 1)]
			var biome := Expansion.biome_for_row(config, row)
			var pool: Array = biome.get("encounters", [])
			if pool.is_empty(): pool = config.encounters
			var enemy_id: String = config.boss.id if kind == "boss" else pool[rng.randi_range(0, pool.size() - 1)]
			var links: Array = []
			if row < int(config.rows) - 1:
				for next_column in range(1 if row == int(config.rows) - 2 else 2):
					links.append("%d_%d" % [row + 1, next_column])
			nodes.append({"id": "%d_%d" % [row, column], "row": row, "column": column, "type": kind, "enemy": enemy_id, "links": links})
	return _tag_biomes(nodes, config)

# El editor necesita dibujar borradores con conexiones rotas para poder repararlas.
# Comparte la resolución de enemigos con el juego, sin exigir topología válida.
static func preview_custom(seed_value: int, config: Dictionary) -> Array:
	if not config.get("route_nodes") is Array or not config.get("encounters") is Array or config.encounters.is_empty() or not config.get("boss") is Dictionary or not config.boss.has("id"): return []
	var custom: Array = config.route_nodes.duplicate(true)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for node in custom:
		if not node is Dictionary or not node.has_all(["id", "row", "column", "type", "enemy", "links"]): return []
		if node.type == "boss": node.enemy = config.boss.id
		elif node.enemy == "":
			var biome := Expansion.biome_for_row(config, int(node.row))
			var pool: Array = biome.get("encounters", [])
			if pool.is_empty(): pool = config.encounters
			node.enemy = pool[rng.randi_range(0, pool.size() - 1)]
	return _tag_biomes(custom, config)

static func _tag_biomes(nodes: Array, config: Dictionary) -> Array:
	if config.has("biomes"):
		for node in nodes: node["biome"] = Expansion.biome_for_row(config, int(node.row)).get("id", "")
	return nodes
