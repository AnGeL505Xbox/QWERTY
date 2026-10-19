extends RefCounted

static func generate(seed_value: int, config: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
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
			var enemy_id: String = config.boss.id if kind == "boss" else config.encounters[rng.randi_range(0, config.encounters.size() - 1)]
			var links: Array = []
			if row < int(config.rows) - 1:
				for next_column in range(1 if row == int(config.rows) - 2 else 2):
					links.append("%d_%d" % [row + 1, next_column])
			nodes.append({"id": "%d_%d" % [row, column], "row": row, "column": column, "type": kind, "enemy": enemy_id, "links": links})
	return nodes
