@tool
class_name RpgBiomeDefinition
extends Resource

@export var id := "nuevo_bioma"
@export var display_name := "Nuevo bioma"
@export_multiline var description := ""
@export_range(0, 7) var first_row := 0
@export_range(0, 7) var last_row := 4
@export var color := Color("5ca3b2")
## Vacío utiliza los encuentros globales; deben ser los mismos Resources registrados.
@export var encounters: Array[RpgEnemyDefinition] = []
## Vacío utiliza los eventos globales.
@export var events: Array[RpgEventDefinition] = []

func to_dict() -> Dictionary:
	return {"id": id, "name": display_name, "description": description, "first_row": first_row, "last_row": last_row, "color": color.to_html(false), "encounters": encounters.map(func(enemy): return enemy.id if enemy != null else ""), "events": events.map(func(event): return event.id if event != null else "")}
