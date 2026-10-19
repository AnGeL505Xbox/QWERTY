extends RefCounted

const Effects = preload("res://core/effects/registry.gd")
const Intent = preload("res://core/enemies/intent.gd")
const Character = preload("res://core/characters/character.gd")

signal changed
signal action(kind: String)
signal actor_action(actor_id: String, kind: String)
signal combat_event(event: Dictionary)

var content: Dictionary
var team: Array = []
var enemy_health: int
var enemy: Dictionary
var enemy_block := 0
var intent: Dictionary
var exhausted: Array = []
var turn := 0
var hand: Array = []
var draw_pile: Array = []
var discard: Array = []
var result := ""
var rng := RandomNumberGenerator.new()
var source_actor
var target_actor

# Compatibilidad con consumidores de fase 1/2: apuntan al primer personaje.
var health: int:
	get: return team[0].health
	set(value): team[0].health = value
var max_health: int:
	get: return team[0].max_health
var block: int:
	get: return team[0].block
	set(value): team[0].block = value
var energy: int:
	get: return team[0].energy
	set(value): team[0].energy = value

func _init(data: Dictionary, seed_value: int = 1, enemy_index: int = 0, team_ids: Array = [], party: Dictionary = {}) -> void:
	content = data
	rng.seed = seed_value
	var ids: Array = data.team if team_ids.is_empty() else team_ids
	assert(ids.size() >= 1 and ids.size() <= 3)
	for id in ids:
		for definition in data.characters:
			if definition.id == id:
				assert(character(id) == null, "Personaje repetido")
				var member = Character.new(definition, data.statuses)
				if party.has(id):
					member.health = int(party[id].health)
					member.stress = int(party[id].stress)
				team.append(member)
				draw_pile.append_array(definition.deck)
	assert(team.size() == ids.size(), "Personaje desconocido")
	enemy = content.enemies[enemy_index].duplicate(true)
	enemy_health = int(enemy.health)
	_shuffle(draw_pile)
	_new_turn()

func character(id: String):
	for member in team:
		if member.id == id:
			return member
	return null

func living() -> Array:
	return team.filter(func(member): return member.alive())

func _shuffle(cards: Array) -> void:
	for i in range(cards.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var value = cards[i]
		cards[i] = cards[j]
		cards[j] = value

func card_data(id: String) -> Dictionary:
	for card in content.cards:
		if card.id == id:
			return card
	return {}

func valid_targets(index: int) -> Array:
	if not result.is_empty() or index < 0 or index >= hand.size():
		return []
	var card := card_data(hand[index])
	if card.is_empty():
		return []
	var owner = character(card.owner)
	if owner == null or not owner.alive() or owner.energy < int(card.cost):
		return []
	for effect in card.effects:
		if not Effects.valid(effect, card.target):
			return []
	if card.target == "ally":
		return living().map(func(member): return member.id)
	return [card.target]

func play(index: int, target: String = "") -> bool:
	var targets := valid_targets(index)
	if targets.is_empty():
		return false
	if target.is_empty():
		target = targets[0]
	if not target in targets:
		return false
	var card := card_data(hand[index])
	source_actor = character(card.owner)
	target_actor = source_actor if target == "self" else character(target)
	source_actor.energy -= int(card.cost)
	var id = hand[index]
	hand.remove_at(index)
	var before := state_snapshot()
	for effect in card.effects:
		Effects.apply(self, effect)
	if card.exhaust:
		exhausted.append(id)
	else:
		discard.append(id)
	if enemy_health == 0:
		result = "Victoria"
	action.emit(str(card.effects[0].type))
	actor_action.emit(source_actor.id, str(card.effects[0].type))
	var animation := "attack" if card.target == "enemy" else "defend"
	if source_actor.definition.special == card.id:
		animation = "special"
	_emit_event(source_actor.id, animation, before)
	changed.emit()
	return true

func end_turn() -> void:
	if not result.is_empty():
		return
	discard.append_array(hand)
	hand.clear()
	enemy_block = 0
	var before := state_snapshot()
	Intent.execute(self, intent)
	var animation := "attack" if intent.type == "attack" else "defend"
	_emit_event("enemy", animation, before)
	for member in team:
		member.finish_round()
	if living().is_empty():
		result = "Derrota"
	else:
		_new_turn()
	changed.emit()

func _new_turn() -> void:
	turn += 1
	for member in team:
		var before := state_snapshot()
		member.start_turn()
		if member.crisis:
			actor_action.emit(member.id, "crisis")
			_emit_event(member.id, "crisis", before)
	intent = Intent.at_turn(enemy, turn)
	if not living().is_empty():
		intent["target"] = living()[0].id
	draw_cards(int(content.balance.hand_size))

func draw_cards(count: int) -> void:
	for i in range(count):
		if draw_pile.is_empty():
			draw_pile = discard.duplicate()
			discard.clear()
			_shuffle(draw_pile)
		if draw_pile.is_empty():
			break
		hand.append(draw_pile.pop_back())

# Eventos de solo lectura: las reglas nunca esperan una animación.
func state_snapshot() -> Dictionary:
	var snapshot := {"enemy": {"health": enemy_health, "shield": enemy_block, "stress": 0, "statuses": {}}}
	for member in team:
		snapshot[member.id] = {"health": member.health, "shield": member.block, "stress": member.stress, "statuses": member.statuses.duplicate()}
	return snapshot

func _emit_event(source: String, animation: String, before: Dictionary) -> void:
	var after := state_snapshot()
	var changes: Array = []
	for id in after:
		var old: Dictionary = before[id]
		var now: Dictionary = after[id]
		var status_names: Array[String] = []
		for status in now.statuses:
			if now.statuses[status] != old.statuses.get(status, 0):
				status_names.append(str(content.statuses[status].name))
		changes.append({"target": id, "health": now.health - old.health, "shield": now.shield - old.shield, "stress": now.stress - old.stress, "status": ", ".join(status_names)})
	combat_event.emit({"source": source, "animation": animation, "changes": changes})

# Guardado de reglas, sin nodos ni recursos gráficos. Los enteros RNG se guardan como texto.
func export_state() -> Dictionary:
	var members: Dictionary = {}
	for member in team:
		members[member.id] = {"health": member.health, "stress": member.stress, "energy": member.energy, "block": member.block, "statuses": member.statuses.duplicate(), "crisis": member.crisis}
	return {"enemy": enemy.id, "enemy_health": enemy_health, "enemy_block": enemy_block, "turn": turn, "intent": intent.duplicate(true), "hand": hand.duplicate(), "draw": draw_pile.duplicate(), "discard": discard.duplicate(), "exhausted": exhausted.duplicate(), "result": result, "members": members, "rng_seed": str(rng.seed), "rng_state": str(rng.state)}

static func restore(data: Dictionary, saved: Dictionary, ids: Array):
	var enemy_index := 0
	for i in range(data.enemies.size()):
		if data.enemies[i].id == saved.enemy:
			enemy_index = i
	var restored = load("res://core/combat/battle.gd").new(data, 1, enemy_index, ids)
	restored.enemy_health = int(saved.enemy_health)
	restored.enemy_block = int(saved.enemy_block)
	restored.turn = int(saved.turn)
	restored.intent = saved.intent.duplicate(true)
	restored.hand = saved.hand.duplicate()
	restored.draw_pile = saved.draw.duplicate()
	restored.discard = saved.discard.duplicate()
	restored.exhausted = saved.exhausted.duplicate()
	restored.result = saved.result
	for member in restored.team:
		var state: Dictionary = saved.members[member.id]
		member.health = int(state.health)
		member.stress = int(state.stress)
		member.energy = int(state.energy)
		member.block = int(state.block)
		member.statuses = state.statuses.duplicate()
		member.crisis = state.crisis
	restored.rng.seed = int(saved.rng_seed)
	restored.rng.state = int(saved.rng_state)
	return restored
