extends RefCounted

# Jugador de prueba: utiliza la API pública, sin alterar vida, pilas ni reglas.
static func fight(battle) -> void:
	for turn_index in range(80):
		if battle.result != "": return
		for action_index in range(40):
			var best := -1
			var best_score := 0.0
			var best_target := ""
			for i in range(battle.hand.size()):
				var card: Dictionary = battle.card_data(battle.hand[i])
				for target in battle.valid_targets(i):
					var receiver = battle.character(card.owner if target == "self" else target)
					var score := 0.0
					for effect in card.effects:
						match effect.type:
							"damage": score += 10.0 + float(effect.amount) + (100.0 if int(effect.amount) >= battle.enemy_health else 0.0)
							"energy": score += 60.0
							"draw": score += 20.0
							"heal": score += 45.0 if receiver.health <= 15 else (8.0 if receiver.health < receiver.max_health else 0.0)
							"block": score += 25.0 if receiver.id == battle.intent.target and receiver.block < 6 else 0.0
							"calm": score += 20.0 if receiver.stress >= receiver.definition.stress_limit - 3 else 0.0
							"status": score += 24.0 if not receiver.statuses.has(effect.status) else 0.0
					if score > best_score:
						best = i
						best_score = score
						best_target = target
			if best < 0: break
			battle.play(best, best_target)
			if battle.result != "": return
		battle.end_turn()
