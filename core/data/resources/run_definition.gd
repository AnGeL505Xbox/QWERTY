@tool
class_name RpgRunDefinition
extends Resource

@export_category("Contenido de la expedición")
@export var reward_table: RpgRewardTable
@export var events: Array[RpgEventDefinition] = []
@export_category("Ruta personalizada (vacía: procedural)")
@export var route_nodes: Array[RpgRouteNode] = []
@export_category("Recorrido y balance")
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
	var config := {"rows": rows, "encounters": ids, "boss": boss.to_dict() if boss != null else {}, "middle_types": Array(middle_types), "starting_gold": starting_gold, "combat_gold": combat_gold, "elite_gold_bonus": elite_gold_bonus, "rest_heal": rest_heal, "stress_relief": stress_relief, "card_price": card_price, "upgrade_price": upgrade_price, "max_upgrade_level": max_upgrade_level, "upgrade_amount": upgrade_amount, "event_gold": event_gold, "event_damage": event_damage, "elite_health_bonus": elite_health_bonus, "elite_damage_bonus": elite_damage_bonus}

	if not route_nodes.is_empty():
		config["route_nodes"] = route_nodes.map(func(node): return node.to_dict() if node != null else {})
	if reward_table != null:
		config["rewards"] = reward_table.to_dict()
	if not events.is_empty():
		config["events"] = []
		for event in events:
			config.events.append(event.to_dict() if event != null else {})
	return config
