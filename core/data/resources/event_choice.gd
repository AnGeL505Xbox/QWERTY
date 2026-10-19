@tool
class_name RpgEventChoice
extends Resource

@export var id := "continuar"
@export_multiline var label := "Continuar"
@export_range(-999, 999) var gold_delta := 0
## Se aplica a integrantes vivos; el daño real añade estrés y la curación no revive.
@export_range(-999, 999) var health_delta := 0
@export_range(-999, 999) var stress_delta := 0
@export var card: RpgCardDefinition

func to_dict() -> Dictionary:
	return {"id": id, "label": label, "gold": gold_delta, "health": health_delta, "stress": stress_delta, "card": card.id if card != null else ""}
