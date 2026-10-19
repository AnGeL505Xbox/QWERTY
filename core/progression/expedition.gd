extends RefCounted

const Route = preload("res://core/progression/route.gd")
const Battle = preload("res://core/combat/battle.gd")
var content: Dictionary
var config: Dictionary
var seed_value: int
var team_ids: Array
var nodes: Array
var visited: Array = []
var current := ""
var phase := "map"
var gold := 0
var party: Dictionary = {}
var upgrades: Dictionary = {}
var offers: Array = []
var battle: RefCounted
var rng := RandomNumberGenerator.new()

func _init(data: Dictionary, rules: Dictionary, run_seed: int, ids: Array) -> void:
	content = data.duplicate(true)
	config = rules.duplicate(true)
	seed_value = run_seed
	team_ids = ids.duplicate()
	gold = int(config.starting_gold)
	rng.seed = seed_value
	content.enemies = content.enemies.filter(func(enemy): return enemy.id != config.boss.id)
	content.enemies.append(config.boss.duplicate(true))
	nodes = Route.generate(seed_value, config)
	for definition in content.characters:
		if definition.id in team_ids:
			party[definition.id] = {"health": int(definition.health), "stress": 0}

func node(id: String) -> Dictionary:
	for entry in nodes:
		if entry.id == id:
			return entry
	return {}

func available() -> Array:
	if phase != "map":
		return []
	if current == "":
		return nodes.filter(func(entry): return entry.row == 0).map(func(entry): return entry.id)
	return node(current).links.duplicate()

func enter(id: String) -> bool:
	if not id in available():
		return false
	current = id
	offers.clear()
	var selected := node(id)
	phase = selected.type
	if phase in ["combat", "elite", "boss"]:
		phase = "combat"
		var data := combat_content()
		var index := 0
		for i in range(data.enemies.size()):
			if data.enemies[i].id == selected.enemy:
				index = i
		battle = Battle.new(data, int(rng.randi()), index, team_ids, party)
	elif phase == "reward":
		_open_rewards()
	elif phase == "shop":
		offers = _card_offers(3)
	return true

func combat_content() -> Dictionary:
	var data: Dictionary = content.duplicate(true)
	for card in data.cards:
		var level := int(upgrades.get(card.id, 0))
		if level > 0:
			for effect in card.effects:
				if effect.type in ["damage", "block", "heal", "calm"]:
					effect.amount = int(effect.amount) + level * int(config.upgrade_amount)
			card.description += "\nMejora +%d: +%d a daño/escudo/curación/calma." % [level, level * int(config.upgrade_amount)]
	if current != "" and node(current).type == "elite":
		for enemy in data.enemies:
			if enemy.id == node(current).enemy:
				enemy.health = int(enemy.health) + int(config.elite_health_bonus)
				for intent in enemy.pattern:
					if intent.type == "attack":
						intent.amount = int(intent.amount) + int(config.elite_damage_bonus)
	return data

func sync_party() -> void:
	if battle == null:
		return
	for member in battle.team:
		party[member.id] = {"health": member.health, "stress": member.stress}

func finish_battle() -> bool:
	if phase != "combat" or battle == null or battle.result == "":
		return false
	sync_party()
	if battle.result == "Derrota":
		phase = "defeat"
	elif node(current).type == "boss":
		visited.append(current)
		phase = "victory"
	else:
		_open_rewards()
	return true

func _open_rewards() -> void:
	phase = "reward"
	gold += int(config.combat_gold)
	if node(current).type == "elite":
		gold += int(config.elite_gold_bonus)
	offers = _card_offers(3)
	for id in upgradeable():
		offers.append({"action": "upgrade", "id": id})
		if offers.size() >= 5:
			break
	offers.append({"action": "skip", "id": ""})

func _card_offers(count: int) -> Array:
	var candidates: Array = content.cards.filter(func(card): return card.owner in team_ids)
	var result: Array = []
	while not candidates.is_empty() and result.size() < count:
		var index := rng.randi_range(0, candidates.size() - 1)
		result.append({"action": "card", "id": candidates[index].id})
		candidates.remove_at(index)
	return result

func card(id: String) -> Dictionary:
	for definition in content.cards:
		if definition.id == id:
			return definition
	return {}

func owned() -> Array:
	var ids: Array = []
	for character in content.characters:
		if character.id in team_ids:
			for id in character.deck:
				if not id in ids:
					ids.append(id)
	return ids

func upgradeable() -> Array:
	return owned().filter(func(id): return int(upgrades.get(id, 0)) < int(config.max_upgrade_level) and card(id).effects.any(func(effect): return effect.type in ["damage", "block", "heal", "calm"]))

func choose(action: String, id: String = "") -> bool:
	if phase == "reward":
		if not {"action": action, "id": id} in offers:
			return false
		if action == "card":
			_add_card(id)
		elif action == "upgrade":
			if not id in upgradeable():
				return false
			upgrades[id] = int(upgrades.get(id, 0)) + 1
		_complete_node()
		return true
	if phase == "rest":
		if action == "heal":
			_heal()
		elif action == "upgrade" and id in upgradeable():
			upgrades[id] = int(upgrades.get(id, 0)) + 1
		else:
			return false
		_complete_node()
		return true
	if phase == "shop":
		if action == "leave":
			_complete_node()
			return true
		if action == "card" and {"action": action, "id": id} in offers and gold >= int(config.card_price):
			gold -= int(config.card_price)
			_add_card(id)
			offers.erase({"action": action, "id": id})
			return true
		if action == "upgrade" and id in upgradeable() and gold >= int(config.upgrade_price):
			gold -= int(config.upgrade_price)
			upgrades[id] = int(upgrades.get(id, 0)) + 1
			return true
	if phase == "event" and action in ["risk", "heal"]:
		if action == "risk":
			gold += int(config.event_gold)
			for definition in content.characters:
				if party.has(definition.id) and party[definition.id].health > 0:
					var member: Dictionary = party[definition.id]
					var lost := mini(int(member.health), int(config.event_damage))
					member.health -= lost
					member.stress = mini(int(definition.stress_limit), int(member.stress) + lost)
		else:
			_heal()
		_complete_node()
		if party.values().all(func(member): return member.health <= 0):
			phase = "defeat"
		return true
	return false

func _heal() -> void:
	for definition in content.characters:
		if party.has(definition.id) and party[definition.id].health > 0:
			var member: Dictionary = party[definition.id]
			member.health = mini(int(definition.health), int(member.health) + int(config.rest_heal))
			member.stress = maxi(0, int(member.stress) - int(config.stress_relief))

func _add_card(id: String) -> void:
	for definition in content.characters:
		if definition.id == card(id).owner:
			definition.deck.append(id)

func _complete_node() -> void:
	visited.append(current)
	phase = "map"
	offers.clear()
	battle = null

func export_state() -> Dictionary:
	return {"seed": str(seed_value), "rng_state": str(rng.state), "content": content.duplicate(true), "config": config.duplicate(true), "team": team_ids.duplicate(), "nodes": nodes.duplicate(true), "visited": visited.duplicate(), "current": current, "phase": phase, "gold": gold, "party": party.duplicate(true), "upgrades": upgrades.duplicate(), "offers": offers.duplicate(true), "battle": battle.export_state() if phase == "combat" and battle != null else {}}

static func restore(saved: Dictionary):
	var base: Dictionary = saved.content.duplicate(true)
	base.enemies = base.enemies.filter(func(enemy): return enemy.id != saved.config.boss.id)
	var run = load("res://core/progression/expedition.gd").new(base, saved.config, int(saved.seed), saved.team)
	run.content = saved.content.duplicate(true)
	run.nodes = saved.nodes.duplicate(true)
	run.visited = saved.visited.duplicate()
	run.current = saved.current
	run.phase = saved.phase
	run.gold = int(saved.gold)
	for id in saved.party:
		run.party[id] = {"health": int(saved.party[id].health), "stress": int(saved.party[id].stress)}
	for id in saved.upgrades:
		run.upgrades[id] = int(saved.upgrades[id])
	run.offers = saved.offers.duplicate(true)
	run.rng.state = int(saved.rng_state)
	if run.phase == "combat":
		run.battle = Battle.restore(run.combat_content(), saved.battle, run.team_ids)
	return run
