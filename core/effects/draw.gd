extends RefCounted

static func apply(battle, amount: int) -> void:
	battle.draw_cards(amount)
