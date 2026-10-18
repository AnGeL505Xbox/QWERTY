extends RefCounted

const Effects = preload("res://core/effects/registry.gd")
const Intent = preload("res://core/enemies/intent.gd")

signal changed
signal action(kind: String)

var content: Dictionary
var health: int
var max_health: int
var enemy_health: int
var enemy: Dictionary
var enemy_block := 0
var intent: Dictionary
var exhausted: Array = []
var block := 0
var energy := 0
var turn := 0
var hand: Array = []
var draw_pile: Array = []
var discard: Array = []
var result := ""
var rng := RandomNumberGenerator.new()

func _init(data: Dictionary, seed_value: int = 1, enemy_index: int = 0) -> void:
	content = data
	rng.seed = seed_value
	max_health = int(content.characters[0].health)
	health = max_health
	enemy = content.enemies[enemy_index].duplicate(true)
	enemy_health = int(enemy.health)
	draw_pile = content.starter_deck.duplicate()
	_shuffle(draw_pile)
	_new_turn()

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
	if card.is_empty() or energy < int(card.cost):
		return []
	for effect in card.effects:
		if not Effects.valid(effect, card.target):
			return []
	return [card.target]

func play(index: int, target: String = "") -> bool:
	var targets := valid_targets(index)
	if targets.is_empty():
		return false
	# Conserva la API de fase 1 para pruebas y clientes sin selección visual.
	if target.is_empty():
		target = targets[0]
	if not target in targets:
		return false
	var card := card_data(hand[index])
	energy -= int(card.cost)
	var id = hand[index]
	hand.remove_at(index)
	# Retirar antes de robar evita reciclar la carta que se está resolviendo.
	for effect in card.effects:
		Effects.apply(self, effect)
	if card.exhaust:
		exhausted.append(id)
	else:
		discard.append(id)
	if enemy_health == 0:
		result = "Victoria"
	action.emit(str(card.effects[0].type))
	changed.emit()
	return true

func end_turn() -> void:
	if not result.is_empty():
		return
	discard.append_array(hand)
	hand.clear()
	enemy_block = 0
	Intent.execute(self, intent)
	if health == 0:
		result = "Derrota"
	else:
		_new_turn()
	changed.emit()

func _new_turn() -> void:
	turn += 1
	intent = Intent.at_turn(enemy, turn)
	block = 0
	energy = int(content.balance.energy)
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
