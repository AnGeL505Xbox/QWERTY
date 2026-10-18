extends RefCounted

static func apply(battle, amount: int) -> void:
	amount += battle.source_actor.stat("attack")
	var absorbed := mini(battle.enemy_block, amount)
	battle.enemy_block -= absorbed
	battle.enemy_health = maxi(0, battle.enemy_health - (amount - absorbed))
