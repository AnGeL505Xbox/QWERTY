@tool
class_name RpgEffectDefinition
extends Resource

@export_enum("damage", "block", "heal", "draw", "energy", "calm", "status") var type := "damage"
@export_range(0, 999, 1) var amount := 7
@export var status: RpgStatusDefinition

func to_dict() -> Dictionary:
	var value := {"type": type, "amount": amount}
	if type == "status":
		value["status"] = status.id if status != null else ""
	return value
