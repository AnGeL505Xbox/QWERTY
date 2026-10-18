extends RefCounted

signal changed
signal action(kind: String)

var content: Dictionary
var health: int
var max_health: int
var enemy_health: int
var block := 0
var energy := 0
var turn := 0
var hand: Array = []
var draw_pile: Array = []
var discard: Array = []
var result := ""
var rng := RandomNumberGenerator.new()

func _init(data: Dictionary, seed_value: int = 1) -> void:
	content = data
	rng.seed = seed_value
	max_health = int(content.characters[0].health)
	health = max_health
	enemy_health = int(content.enemies[0].health)
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

func play(index: int) -> bool:
	if not result.is_empty() or index < 0 or index >= hand.size():
		return false
	var card := card_data(hand[index])
	if energy < int(card.cost):
		return false
	energy -= int(card.cost)
	for effect in card.effects:
		match effect.type:
			"damage": enemy_health = maxi(0, enemy_health - int(effect.amount))
			"block": block += int(effect.amount)
			"heal": health = mini(max_health, health + int(effect.amount))
	discard.append(hand[index])
	hand.remove_at(index)
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
	health = maxi(0, health - maxi(0, int(content.enemies[0].damage) - block))
	action.emit("hurt")
	if health == 0:
		result = "Derrota"
	else:
		_new_turn()
	changed.emit()

func _new_turn() -> void:
	turn += 1
	block = 0
	energy = int(content.balance.energy)
	for i in range(int(content.balance.hand_size)):
		if draw_pile.is_empty():
			draw_pile = discard.duplicate()
			discard.clear()
			_shuffle(draw_pile)
		if draw_pile.is_empty():
			break
		hand.append(draw_pile.pop_back())
