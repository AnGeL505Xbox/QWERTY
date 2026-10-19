@tool
extends RefCounted

const Catalog = preload("res://core/data/catalog.gd")
const RunValidator = preload("res://core/save_system/run_validator.gd")
const GROUPS = {"card": "cards", "character": "characters", "enemy": "enemies", "status": "statuses", "reward": "rewards", "event": "events"}

# Prepara una propuesta sin escribir ni modificar los recursos del usuario.
static func plan(kind: String, id: String, title: String, catalog: RpgContentCatalog, rules: RpgRunDefinition, source: Resource = null, owner_id: String = "", activate_reward: bool = false, directory: String = "res://data") -> Dictionary:
	var errors := PackedStringArray()
	var pattern := RegEx.new()
	pattern.compile("^[a-z][a-z0-9_]{0,47}$")
	if not GROUPS.has(kind) or pattern.search(id) == null:
		errors.append("Usa un ID de 1–48 caracteres: letras minúsculas, números y guion bajo; comienza con letra.")
	if catalog == null or rules == null:
		errors.append("Selecciona un catálogo y una configuración de expedición.")
	if directory.simplify_path() != directory or not (directory == "res://data" or directory.begins_with("res://data/")):
		errors.append("La carpeta debe estar dentro de res://data/.")
	if source != null and kind_of(source) != kind:
		errors.append("El recurso seleccionado no corresponde al tipo solicitado.")
	if not errors.is_empty(): return {"errors": errors}
	var proposed := RpgContentCatalog.new()
	for group in ["cards", "characters", "enemies", "statuses", "team"]:
		proposed.set(group, catalog.get(group).duplicate())
	proposed.hand_size = catalog.hand_size
	var proposed_rules: RpgRunDefinition = rules.duplicate(false)
	proposed_rules.events = rules.events.duplicate()
	proposed_rules.encounters = rules.encounters.duplicate()
	var created: Resource
	var files: Array = []
	match kind:
		"card":
			created = _clone_card(source) if source != null else _card(id, "lira", false)
			created.owner = owner_id if owner_id != "" else (source.owner if source != null else catalog.characters[0].id if not catalog.characters.is_empty() else "")
			proposed.cards.append(created)
		"character":
			created = source.duplicate(false) if source != null else RpgCharacterDefinition.new()
			var empty_deck: Array[RpgCardDefinition] = []
			created.deck = empty_deck
			var mapping: Dictionary = {}
			if source != null:
				var originals: Array = Array(source.deck)
				if source.special != null and not source.special in originals: originals.append(source.special)
				for card in originals:
					if card == null or mapping.has(card.id): continue
					var copy := _clone_card(card)
					copy.id = id + "_carta_" + str(mapping.size() + 1)
					copy.owner = id
					mapping[card.id] = copy
					proposed.cards.append(copy)
					files.append(_file(directory, "cards", copy))
				for card in source.deck:
					if card != null: created.deck.append(mapping[card.id])
				created.special = mapping.get(source.special.id) if source.special != null else null
			else:
				var attack := _card(id + "_ataque", id, false)
				var special := _card(id + "_especial", id, true)
				proposed.cards.append_array([attack, special])
				files.append(_file(directory, "cards", attack))
				files.append(_file(directory, "cards", special))
				created.deck.assign([attack, attack, attack, special])
				created.special = special
			proposed.characters.append(created)
		"enemy":
			created = source.duplicate(false) if source != null else RpgEnemyDefinition.new()
			var empty_pattern: Array[RpgIntentDefinition] = []
			created.pattern = empty_pattern
			if source != null:
				for intent in source.pattern:
					created.pattern.append(intent.duplicate(false) if intent != null else null)
			else:
				var attack := RpgIntentDefinition.new()
				created.pattern.append(attack)
			proposed.enemies.append(created)
		"status":
			created = source.duplicate(false) if source != null else RpgStatusDefinition.new()
			proposed.statuses.append(created)
		"reward":
			created = source.duplicate(false) if source != null else RpgRewardTable.new()
			if activate_reward or rules.reward_table == null: proposed_rules.reward_table = created
		"event":
			created = source.duplicate(false) if source != null else RpgEventDefinition.new()
			var empty_choices: Array[RpgEventChoice] = []
			created.choices = empty_choices
			if source != null:
				for choice in source.choices:
					created.choices.append(choice.duplicate(false) if choice != null else null)
			else: created.choices.append(RpgEventChoice.new())
			proposed_rules.events.append(created)
	created.id = id
	created.display_name = title.strip_edges() if not title.strip_edges().is_empty() else id.capitalize()
	files.append(_file(directory, GROUPS[kind], created))
	var paths: Array = []
	for file in files:
		if file.path in paths or FileAccess.file_exists(file.path): errors.append("El archivo ya existe o está repetido: " + file.path)
		paths.append(file.path)
	# La tabla puede guardarse sin activarse. También se comprueba su configuración candidata.
	errors.append_array(Catalog.validate_resource(proposed))
	errors.append_array(RunValidator.resource_configuration(proposed, proposed_rules))
	if kind == "reward" and proposed_rules.reward_table != created:
		var check_rules: RpgRunDefinition = proposed_rules.duplicate(false)
		check_rules.reward_table = created
		errors.append_array(RunValidator.resource_configuration(proposed, check_rules))
	return {"errors": errors, "catalog": proposed, "rules": proposed_rules, "resource": created, "files": files}

static func persist_new(proposal: Dictionary) -> String:
	if not proposal.has("errors") or not proposal.errors.is_empty(): return "La propuesta tiene errores."
	for file in proposal.files:
		if FileAccess.file_exists(file.path): return "No se sobrescribe " + file.path
	var written: Array[String] = []
	for file in proposal.files:
		var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(file.path.get_base_dir()))
		if error == OK: error = ResourceSaver.save(file.resource, file.path, ResourceSaver.FLAG_CHANGE_PATH)
		if error != OK:
			for path in written: DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			return "No se pudo crear " + file.path + ". No se registró el contenido."
		written.append(file.path)
	return ""

static func kind_of(resource: Resource) -> String:
	if resource is RpgCardDefinition: return "card"
	if resource is RpgCharacterDefinition: return "character"
	if resource is RpgEnemyDefinition: return "enemy"
	if resource is RpgStatusDefinition: return "status"
	if resource is RpgRewardTable: return "reward"
	if resource is RpgEventDefinition: return "event"
	return ""

static func _file(directory: String, group: String, resource: Resource) -> Dictionary:
	return {"path": directory + "/" + group + "/" + resource.id + ".tres", "resource": resource}

static func _card(id: String, owner: String, special: bool) -> RpgCardDefinition:
	var card := RpgCardDefinition.new()
	card.id = id
	card.owner = owner
	card.display_name = "Habilidad especial" if special else "Ataque básico"
	card.cost = 2 if special else 1
	card.exhaust = special
	var effect := RpgEffectDefinition.new()
	effect.amount = 16 if special else 7
	card.effects.append(effect)
	card.description = "Inflige %d de daño.%s" % [effect.amount, " Se agota." if special else ""]
	return card

static func _clone_card(source: RpgCardDefinition) -> RpgCardDefinition:
	var copy: RpgCardDefinition = source.duplicate(false)
	copy.effects = []
	for effect in source.effects:
		# Incluso efectos externos se independizan; las referencias a estados conservan su identidad.
		copy.effects.append(effect.duplicate(false) if effect != null else null)
	return copy
