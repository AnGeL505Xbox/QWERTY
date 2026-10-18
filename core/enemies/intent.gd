extends RefCounted

static func at_turn(enemy: Dictionary, turn: int) -> Dictionary:
	var pattern: Array = enemy.pattern
	return pattern[(turn - 1) % pattern.size()].duplicate()

static func describe(intent: Dictionary) -> String:
	match intent.type:
		"attack": return "Atacar por %d" % intent.amount
		"guard": return "Obtener %d de escudo" % intent.amount
	return "Recuperar %d de vida" % intent.amount

static func execute(battle, intent: Dictionary) -> void:
	match intent.type:
		"attack":
			battle.health = maxi(0, battle.health - maxi(0, int(intent.amount) - battle.block))
			battle.action.emit("hurt")
		"guard": battle.enemy_block += int(intent.amount)
		"heal": battle.enemy_health = mini(int(battle.enemy.health), battle.enemy_health + int(intent.amount))
