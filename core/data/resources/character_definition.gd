@tool
class_name RpgCharacterDefinition
extends Resource

@export_category("Identidad")
@export var id := "nuevo_personaje"
@export var display_name := "Nuevo personaje"
@export var affinity := "nácar"
@export var color := Color.WHITE
@export var visual_profile: RpgVisualProfile
@export_category("Estadísticas")
@export_range(1, 999, 1) var health := 40
@export_range(0, 99, 1) var attack := 0
@export_range(0, 99, 1) var defense := 0
@export_range(1, 99, 1) var energy := 3
@export_category("Estrés y crisis")
@export_range(1, 999, 1) var stress_limit := 10
@export_range(0, 99, 1) var crisis_energy_loss := 1
@export_range(1, 999, 1) var crisis_relief := 6
@export_category("Pasivas")
@export_range(0, 99, 1) var passive_start_block := 0
@export_range(0, 99, 1) var passive_stress_relief := 0
@export_category("Mazo y habilidad especial")
@export var deck: Array[RpgCardDefinition] = []
@export var special: RpgCardDefinition

func to_dict() -> Dictionary:
	var ids: Array = []
	for card in deck:
		ids.append(card.id if card != null else "")
	return {"id": id, "name": display_name, "health": health, "attack": attack, "defense": defense, "energy": energy, "affinity": affinity, "color": color.to_html(false), "stress_limit": stress_limit, "crisis": {"energy_loss": crisis_energy_loss, "relief": crisis_relief}, "passive": {"start_block": passive_start_block, "stress_relief": passive_stress_relief}, "deck": ids, "special": special.id if special != null else ""}
