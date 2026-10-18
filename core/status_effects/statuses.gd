extends RefCounted

# Estados temporales con modificadores definidos en el catálogo.
static func modifier(statuses: Dictionary, definitions: Dictionary, stat: String) -> int:
	var total := 0
	for id in statuses:
		total += int(definitions[id].get(stat, 0))
	return total

static func tick(statuses: Dictionary) -> void:
	for id in statuses.keys():
		statuses[id] -= 1
		if statuses[id] <= 0:
			statuses.erase(id)
