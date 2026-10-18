@tool
class_name RpgContentCatalog
extends Resource

@export var cards: Array[RpgCardDefinition] = []
@export var characters: Array[RpgCharacterDefinition] = []
@export var enemies: Array[RpgEnemyDefinition] = []
@export var statuses: Array[RpgStatusDefinition] = []
@export var team: Array[RpgCharacterDefinition] = []
@export_range(1, 20, 1) var hand_size := 5

func to_dict() -> Dictionary:
	var data := {"version": 2, "cards": [], "characters": [], "enemies": [], "statuses": {}, "team": [], "balance": {"hand_size": hand_size}}
	for card in cards:
		data.cards.append(card.to_dict() if card != null else {})
	for character in characters:
		data.characters.append(character.to_dict() if character != null else {})
	for enemy in enemies:
		data.enemies.append(enemy.to_dict() if enemy != null else {})
	for status in statuses:
		if status != null:
			data.statuses[status.id] = status.to_dict()
	for member in team:
		data.team.append(member.id if member != null else "")
	return data

func visual_profiles() -> Dictionary:
	var profiles: Dictionary = {}
	for definition in characters + enemies:
		if definition != null:
			profiles[definition.id] = definition.visual_profile
	return profiles

func artwork() -> Dictionary:
	var images: Dictionary = {}
	for card in cards:
		if card != null and card.illustration != null:
			images[card.id] = card.illustration
	return images
