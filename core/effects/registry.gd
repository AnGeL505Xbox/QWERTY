extends RefCounted

# Cada entrada declara su destino y un módulo con apply(battle, amount).
const DEFINITIONS = {
	"damage": {"target": "enemy", "handler": preload("res://core/effects/damage.gd")},
	"block": {"target": "self", "handler": preload("res://core/effects/block.gd")},
	"heal": {"target": "self", "handler": preload("res://core/effects/heal.gd")},
	"draw": {"target": "self", "handler": preload("res://core/effects/draw.gd")},
	"energy": {"target": "self", "handler": preload("res://core/effects/energy.gd")}
}

static func valid(effect: Dictionary, target: String) -> bool:
	var kind: String = str(effect.get("type", ""))
	if not DEFINITIONS.has(kind):
		return false
	var amount = effect.get("amount", -1)
	return (amount is int or amount is float) and amount >= 0 and amount == int(amount) and DEFINITIONS[kind].target == target

static func apply(battle, effect: Dictionary) -> void:
	DEFINITIONS[effect.type].handler.apply(battle, int(effect.amount))
