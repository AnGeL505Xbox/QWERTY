@tool
class_name RpgRelicDefinition
extends Resource

@export var id := "nueva_reliquia"
@export var display_name := "Nueva reliquia"
@export_multiline var description := ""
@export_range(0, 10) var turn_block := 1
@export_range(0, 2) var turn_energy := 0
@export_range(0, 10) var victory_heal := 0
@export_range(0, 30) var victory_gold := 0

func to_dict() -> Dictionary:
	return {"id": id, "name": display_name, "description": description, "turn_block": turn_block, "turn_energy": turn_energy, "victory_heal": victory_heal, "victory_gold": victory_gold}
