extends RefCounted

static func apply(battle, amount: int) -> void:
	battle.target_actor.stress = maxi(0, battle.target_actor.stress - amount)
