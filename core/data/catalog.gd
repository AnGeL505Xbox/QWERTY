@tool
extends RefCounted

const Validator = preload("res://core/data/validator.gd")
const DEFAULT_PATH = "res://data/catalog.tres"

static func load_content(source: Resource = null) -> Dictionary:
	var resource = source if source != null else load(DEFAULT_PATH)
	if resource == null or not resource.has_method("to_dict"):
		push_error("El catálogo no es un RpgContentCatalog válido.")
		return {}
	var errors := validate_resource(resource)
	if not errors.is_empty():
		push_error("Contenido inválido:\n" + "\n".join(errors))
		return {}
	return resource.to_dict()

static func validate_resource(source: Resource) -> PackedStringArray:
	if not source is RpgContentCatalog:
		return PackedStringArray(["Falta un catálogo de contenido válido."])
	var errors := Validator.validate(source.to_dict())
	var status_ids: Array = []
	for status in source.statuses:
		if status == null or status.id.is_empty() or status.id in status_ids:
			errors.append("Estado nulo, sin ID o repetido.")
		else:
			status_ids.append(status.id)
	for member in source.team:
		if member != null and not member in source.characters:
			errors.append("Team contiene un recurso que no está en Characters.")
	for character in source.characters:
		if character == null:
			continue
		for card in character.deck:
			if card != null and not card in source.cards:
				errors.append("Mazo de " + character.id + ": registra el mismo recurso de carta en Cards.")
		if character.special != null and not character.special in source.cards:
			errors.append("Especial de " + character.id + ": recurso no registrado en Cards.")
	for card in source.cards:
		if card == null:
			continue
		for effect in card.effects:
			if effect != null and effect.type == "status" and effect.status != null and not effect.status in source.statuses:
				errors.append("Carta " + card.id + ": registra el mismo recurso de estado en Statuses.")
	return errors
