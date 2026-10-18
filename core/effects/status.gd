extends RefCounted

static func apply(battle, effect: Dictionary) -> void:
	battle.target_actor.add_status(effect.status, int(effect.amount))
