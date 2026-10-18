@tool
class_name RpgEnemyDefinition
extends Resource

@export var id := "nuevo_enemigo"
@export var display_name := "Nuevo enemigo"
@export_range(1, 9999, 1) var health := 32
@export var pattern: Array[RpgIntentDefinition] = []
@export var visual_profile: RpgVisualProfile

func to_dict() -> Dictionary:
	var intents: Array = []
	for intent in pattern:
		intents.append(intent.to_dict() if intent != null else {})
	return {"id": id, "name": display_name, "health": health, "pattern": intents}
