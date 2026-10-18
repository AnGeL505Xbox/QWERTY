extends RefCounted

static func apply(battle, amount: int) -> void:
	battle.source_actor.energy += amount
