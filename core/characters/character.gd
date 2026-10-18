extends RefCounted

const Statuses = preload("res://core/status_effects/statuses.gd")
var definition: Dictionary
var definitions: Dictionary
var id: String
var health: int
var max_health: int
var energy := 0
var block := 0
var stress := 0
var statuses: Dictionary = {}
var crisis := false

func _init(data: Dictionary, status_definitions: Dictionary) -> void:
	definition = data.duplicate(true)
	definitions = status_definitions
	id = data.id
	max_health = int(data.health)
	health = max_health

func alive() -> bool:
	return health > 0

func stat(key: String) -> int:
	return maxi(0, int(definition.get(key, 0)) + Statuses.modifier(statuses, definitions, key))

func receive_damage(amount: int) -> int:
	var remaining := maxi(0, amount - stat("defense"))
	var absorbed := mini(block, remaining)
	block -= absorbed
	var lost := mini(health, remaining - absorbed)
	health -= lost
	stress = mini(int(definition.stress_limit), stress + lost)
	return lost

func start_turn() -> void:
	crisis = false
	block = 0
	if not alive():
		energy = 0
		return
	energy = stat("energy")
	if stress >= int(definition.stress_limit):
		crisis = true
		energy = maxi(0, energy - int(definition.crisis.energy_loss))
		stress = maxi(0, stress - int(definition.crisis.relief))
	block += int(definition.passive.get("start_block", 0))
	stress = maxi(0, stress - int(definition.passive.get("stress_relief", 0)))

func add_status(id_value: String, duration: int) -> void:
	# Refrescar conserva la mayor duración; no acumula magnitudes.
	statuses[id_value] = maxi(int(statuses.get(id_value, 0)), duration)

func finish_round() -> void:
	Statuses.tick(statuses)
