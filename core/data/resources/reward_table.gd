@tool
class_name RpgRewardTable
extends Resource

@export var id := "nuevas_recompensas"
@export var display_name := "Recompensas"
@export_range(0, 5) var card_choices := 3
@export_range(0, 5) var upgrade_choices := 2
@export var allow_skip := true
## Vacío utiliza todas las cartas del catálogo que pertenecen al equipo.
@export var cards: Array[RpgCardDefinition] = []

func to_dict() -> Dictionary:
	var ids: Array = []
	for card in cards:
		ids.append(card.id if card != null else "")
	return {"id": id, "name": display_name, "card_choices": card_choices, "upgrade_choices": upgrade_choices, "allow_skip": allow_skip, "pool": ids}
