@tool
class_name RpgRouteNode
extends Resource

@export_range(0, 7) var row := 0
@export_range(0, 1) var column := 0
@export_enum("combat", "elite", "event", "reward", "rest", "shop", "boss") var type := "combat"
## Vacío elige enemigo por semilla. El jefe usa siempre la configuración de expedición.
@export var enemy: RpgEnemyDefinition
@export var links := PackedStringArray()

func to_dict() -> Dictionary:
	return {"id": "%d_%d" % [row, column], "row": row, "column": column, "type": type, "enemy": enemy.id if enemy != null else "", "links": Array(links)}
