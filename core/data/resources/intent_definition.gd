@tool
class_name RpgIntentDefinition
extends Resource

@export_enum("attack", "guard", "heal") var type := "attack"
@export_range(0, 999, 1) var amount := 6

func to_dict() -> Dictionary:
	return {"type": type, "amount": amount}
