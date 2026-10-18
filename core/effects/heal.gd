extends RefCounted

static func apply(battle, amount: int) -> void:
	battle.target_actor.health = mini(battle.target_actor.max_health, battle.target_actor.health + amount)
