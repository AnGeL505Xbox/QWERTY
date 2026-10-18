extends RefCounted

static func apply(battle, amount: int) -> void:
	battle.health = mini(battle.max_health, battle.health + amount)
