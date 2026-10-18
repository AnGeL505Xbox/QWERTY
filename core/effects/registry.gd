extends RefCounted

# Cada entrada declara su destino y un módulo con apply(battle, amount).
const StatusEffect = preload("res://core/effects/status.gd")
const DEFINITIONS = {
	"calm": {"target": "self", "handler": preload("res://core/effects/calm.gd")},
	"damage": {"target": "enemy", "handler": preload("res://core/effects/damage.gd")},
	"block": {"target": "self", "handler": preload("res://core/effects/block.gd")},
	"heal": {"target": "self", "handler": preload("res://core/effects/heal.gd")},
	"draw": {"target": "self", "handler": preload("res://core/effects/draw.gd")},
	"energy": {"target": "self", "handler": preload("res://core/effects/energy.gd")}
}

static func valid(effect: Dictionary, target: String) -> bool:
	var kind: String = str(effect.get("type", ""))
	if kind == "status":
		var duration = effect.get("amount", 0)
		return target in ["self", "ally"] and effect.get("status", "") != "" and (duration is int or duration is float) and duration > 0 and duration == int(duration)
	if not DEFINITIONS.has(kind):
		return false
	var amount = effect.get("amount", -1)
	return (amount is int or amount is float) and amount >= 0 and amount == int(amount) and (DEFINITIONS[kind].target == target or (target == "ally" and kind in ["heal", "block", "calm"]))

static func apply(battle, effect: Dictionary) -> void:
	if effect.type == "status":
		StatusEffect.apply(battle, effect)
	else:
		DEFINITIONS[effect.type].handler.apply(battle, int(effect.amount))
