@tool
class_name RpgCardDefinition
extends Resource

@export_category("Identidad")
@export var id := "nueva_carta"
@export var display_name := "Nueva carta"
@export var owner := "lira"
@export_multiline var description := "Describe los efectos de la carta."
@export var illustration: Texture2D
@export_category("Reglas")
@export_range(0, 99, 1) var cost := 1
@export_enum("enemy", "self", "ally") var target := "enemy"
@export var exhaust := false
@export var effects: Array[RpgEffectDefinition] = []

func to_dict() -> Dictionary:
	var effect_data: Array = []
	for effect in effects:
		effect_data.append(effect.to_dict() if effect != null else {})
	return {"id": id, "name": display_name, "owner": owner, "description": description, "cost": cost, "target": target, "exhaust": exhaust, "effects": effect_data}
