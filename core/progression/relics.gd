extends RefCounted

const FIELDS = ["turn_block", "turn_energy", "victory_heal", "victory_gold"]

static func definition(config: Dictionary, id: String) -> Dictionary:
	for relic in config.get("relics", []):
		if relic.id == id: return relic
	return {}

static func bonuses(config: Dictionary, ids: Array) -> Dictionary:
	var result := {"turn_block": 0, "turn_energy": 0, "victory_heal": 0, "victory_gold": 0}
	for id in ids:
		var relic := definition(config, id)
		for field in FIELDS: result[field] += int(relic.get(field, 0))
	return result

static func apply_combat(data: Dictionary, config: Dictionary, ids: Array) -> void:
	var total := bonuses(config, ids)
	for character in data.characters:
		character.energy = int(character.energy) + int(total.turn_energy)
		character.passive.start_block = int(character.passive.start_block) + int(total.turn_block)

static func heal_after_victory(party: Dictionary, content: Dictionary, amount: int) -> void:
	for character in content.characters:
		if party.has(character.id) and party[character.id].health > 0:
			party[character.id].health = mini(int(character.health), int(party[character.id].health) + amount)
