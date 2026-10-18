@tool
class_name RpgStatusDefinition
extends Resource

@export var id := "nuevo_estado"
@export var display_name := "Nuevo estado"
@export var attack := 0
@export var defense := 0

func to_dict() -> Dictionary:
	return {"name": display_name, "attack": attack, "defense": defense}
