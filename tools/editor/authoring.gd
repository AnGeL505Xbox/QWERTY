@tool
extends RefCounted

const Catalog = preload("res://core/data/catalog.gd")
const RunValidator = preload("res://core/save_system/run_validator.gd")

static func resources(catalog: RpgContentCatalog, rules: RpgRunDefinition) -> Array[Resource]:
	var result: Array[Resource] = []
	var pending: Array = [catalog, rules]
	while not pending.is_empty():
		var resource = pending.pop_back()
		if resource == null or resource in result: continue
		if not _supported(resource): continue
		result.append(resource)
		for property in resource.get_property_list():
			if not (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE): continue
			var value = resource.get(property.name)
			if value is Resource: pending.append(value)
			elif value is Array:
				for entry in value:
					if entry is Resource: pending.append(entry)
	return result

static func issues(catalog: RpgContentCatalog, rules: RpgRunDefinition) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var errors := Catalog.validate_resource(catalog)
	if errors.is_empty(): errors.append_array(RunValidator.resource_configuration(catalog, rules))
	var all := resources(catalog, rules)
	for message in errors:
		var target: Resource = rules if message.begins_with("Evento") or message.begins_with("Recompensas") or message.begins_with("Ruta") or message.begins_with("Bioma") or message.begins_with("Reliquia") else catalog
		for resource in all:
			if resource is RpgCardDefinition and message.begins_with("Carta " + resource.id + ":"): target = resource
			elif resource is RpgCharacterDefinition and message.begins_with("Personaje " + resource.id + ":"): target = resource
			elif resource is RpgEnemyDefinition and message.begins_with("Enemigo " + resource.id + ":"): target = resource
			elif resource is RpgEventDefinition and message.begins_with("Evento " + resource.id + ":"): target = resource
			elif resource is RpgRewardTable and message.begins_with("Recompensas:"): target = resource
			if resource is RpgRelicDefinition and message.begins_with("Reliquia " + resource.id + ":"): target = resource
			elif resource is RpgBiomeDefinition and message.begins_with("Bioma " + resource.id + ":"): target = resource
		result.append({"message": message, "resource": target})
	return result

static func save_all(catalog: RpgContentCatalog, rules: RpgRunDefinition) -> Dictionary:
	var problems := issues(catalog, rules)
	if not problems.is_empty(): return {"saved": [], "errors": problems.map(func(issue): return issue.message)}
	var saved: Array[String] = []
	var errors: Array[String] = []
	for resource in resources(catalog, rules):
		var path := resource.resource_path
		if path.contains("::") or path == "": continue # Subrecursos se guardan dentro de su archivo propietario.
		if not path.begins_with("res://") or not path.ends_with(".tres"):
			errors.append("Ruta no admitida: " + path)
			continue
		if ResourceSaver.save(resource, path) != OK: errors.append("No se pudo guardar " + path)
		else: saved.append(path)
	return {"saved": saved, "errors": errors}

static func _supported(resource: Resource) -> bool:
	return resource is RpgContentCatalog or resource is RpgRunDefinition or resource is RpgCardDefinition or resource is RpgCharacterDefinition or resource is RpgEnemyDefinition or resource is RpgStatusDefinition or resource is RpgEffectDefinition or resource is RpgIntentDefinition or resource is RpgRewardTable or resource is RpgEventDefinition or resource is RpgEventChoice or resource is RpgRouteNode or resource is RpgRelicDefinition or resource is RpgBiomeDefinition
