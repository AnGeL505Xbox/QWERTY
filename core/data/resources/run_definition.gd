@tool
class_name RpgRunDefinition
extends Resource

@export_range(4, 8) var rows := 5
@export var encounters: Array[RpgEnemyDefinition] = []
@export var boss: RpgEnemyDefinition
@export var middle_types := PackedStringArray(["combat", "event", "reward", "rest", "shop"])
@export_range(0, 999) var starting_gold := 20
@export_range(0, 999) var combat_gold := 12
@export_range(0, 999) var elite_gold_bonus := 8
@export_range(1, 99) var rest_heal := 8
@export_range(0, 99) var stress_relief := 6
@export_range(1, 999) var card_price := 10
@export_range(1, 999) var upgrade_price := 15
@export_range(1, 5) var max_upgrade_level := 3
@export_range(1, 9) var upgrade_amount := 2
@export_range(0, 999) var event_gold := 18
@export_range(0, 99) var event_damage := 3
@export_range(0, 99) var elite_health_bonus := 12
@export_range(0, 99) var elite_damage_bonus := 2

func to_dict() -> Dictionary:
	var ids: Array = []
	for enemy in encounters:
		ids.append(enemy.id if enemy != null else "")
	return {"rows": rows, "encounters": ids, "boss": boss.to_dict() if boss != null else {}, "middle_types": Array(middle_types), "starting_gold": starting_gold, "combat_gold": combat_gold, "elite_gold_bonus": elite_gold_bonus, "rest_heal": rest_heal, "stress_relief": stress_relief, "card_price": card_price, "upgrade_price": upgrade_price, "max_upgrade_level": max_upgrade_level, "upgrade_amount": upgrade_amount, "event_gold": event_gold, "event_damage": event_damage, "elite_health_bonus": elite_health_bonus, "elite_damage_bonus": elite_damage_bonus}
