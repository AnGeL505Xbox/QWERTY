extends RefCounted

static func apply(battle, amount: int) -> void:
	battle.target_actor.block += amount
