@tool
extends RefCounted

const Catalog = preload("res://core/data/catalog.gd")
const Validator = preload("res://core/save_system/run_validator.gd")
const Route = preload("res://core/progression/route.gd")

static func deck_proposal(catalog: RpgContentCatalog, character: RpgCharacterDefinition, deck: Array[RpgCardDefinition], special: RpgCardDefinition) -> Dictionary:
	if not character in catalog.characters: return {"errors": PackedStringArray(["Personaje ajeno al catálogo."])}
	var candidate: RpgCharacterDefinition = character.duplicate(false)
	candidate.deck = deck.duplicate()
	candidate.special = special
	var probe: RpgContentCatalog = catalog.duplicate(false)
	probe.characters = catalog.characters.duplicate()
	probe.characters[catalog.characters.find(character)] = candidate
	probe.team = catalog.team.duplicate()
	for index in range(probe.team.size()):
		if probe.team[index] == character: probe.team[index] = candidate
	return {"errors": Catalog.validate_resource(probe), "target": character, "changes": {"deck": candidate.deck, "special": special}}

static func event_draft(event: RpgEventDefinition) -> RpgEventDefinition:
	var draft: RpgEventDefinition = event.duplicate(false)
	draft.choices = []
	for choice in event.choices: draft.choices.append(choice.duplicate(false) if choice != null else null)
	return draft

static func event_proposal(catalog: RpgContentCatalog, rules: RpgRunDefinition, event: RpgEventDefinition, draft: RpgEventDefinition) -> Dictionary:
	if not event in rules.events: return {"errors": PackedStringArray(["Evento ajeno a la expedición."])}
	var probe: RpgRunDefinition = rules.duplicate(false)
	probe.events = rules.events.duplicate()
	probe.events[rules.events.find(event)] = draft
	# Copias nuevas para que seguir editando el borrador no cambie un registro ya aplicado.
	var copy := event_draft(draft)
	return {"errors": Validator.resource_configuration(catalog, probe), "target": event, "changes": {"id": copy.id, "display_name": copy.display_name, "description": copy.description, "choices": copy.choices}}

static func route_draft(rules: RpgRunDefinition, seed_value: int) -> Array[RpgRouteNode]:
	var result: Array[RpgRouteNode] = []
	if not rules.route_nodes.is_empty():
		for node in rules.route_nodes: result.append(node.duplicate(false) if node != null else null)
		return result
	for entry in Route.generate(seed_value, rules.to_dict()):
		var node := RpgRouteNode.new()
		node.row = entry.row
		node.column = entry.column
		node.type = entry.type
		node.links = PackedStringArray(entry.links)
		# Se conserva la elección por semilla hasta que el autor fije un enemigo.
		result.append(node)
	return result

static func route_proposal(catalog: RpgContentCatalog, rules: RpgRunDefinition, nodes: Array[RpgRouteNode], rows: int) -> Dictionary:
	var probe: RpgRunDefinition = rules.duplicate(false)
	probe.rows = rows
	probe.route_nodes = []
	for node in nodes: probe.route_nodes.append(node.duplicate(false) if node != null else null)
	return {"errors": Validator.resource_configuration(catalog, probe), "target": rules, "changes": {"rows": rows, "route_nodes": probe.route_nodes}}
