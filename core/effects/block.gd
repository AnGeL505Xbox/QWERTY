extends RefCounted

static func apply(battle, amount: int) -> void:
	battle.block += amount
