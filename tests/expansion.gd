extends SceneTree
const Catalog = preload("res://core/data/catalog.gd")
const Validator = preload("res://core/save_system/run_validator.gd")
const Expedition = preload("res://core/progression/expedition.gd")
const Route = preload("res://core/progression/route.gd")
const Relics = preload("res://core/progression/relics.gd")
const Store = preload("res://core/save_system/store.gd")
const Editing = preload("res://tools/editor/editing.gd")
const Factory = preload("res://tools/editor/content_factory.gd")
const Autoplay = preload("res://tests/support/autoplay.gd")
var checks := 0
var failures := 0
const PATH = "user://test_expansion.json"
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		push_error(message)
		failures += 1
func canonical(value): return JSON.parse_string(JSON.stringify(value))
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var catalog: RpgContentCatalog = load(Catalog.DEFAULT_PATH)
	var rules: RpgRunDefinition = load("res://data/progression/expanded_expedition.tres")
	var data := catalog.to_dict()
	var config := rules.to_dict()
	var initial_data := data.duplicate(true)
	var initial_config := config.duplicate(true)
	check(Catalog.validate_resource(catalog).is_empty() and Validator.resource_configuration(catalog, rules).is_empty(), "Catálogo y expedición ampliados válidos")
	check(data.cards.size() == 20 and data.enemies.size() == 4, "Veinte cartas y cuatro enemigos de entrenamiento")
	check(config.biomes.size() == 2 and config.relics.size() == 4 and config.events.size() == 3, "Contenido de expansión completo")
	for seed_value in [0, 42, 88, 999]:
		var route := Route.generate(seed_value, config)
		check(route == Route.generate(seed_value, config), "Biomas reproducibles con semilla " + str(seed_value))
		var valid := true
		for node in route:
			var biome := preload("res://core/data/expansion_validator.gd").biome_for_row(config, int(node.row))
			valid = valid and node.biome == biome.id and (node.type == "boss" or node.enemy in biome.encounters)
		check(valid, "Cada encuentro respeta el pool y tramo de su bioma")
	for id in ["estocada", "paso_bruma", "respiro", "farol", "marea", "eco_reflejado"]:
		var combat = preload("res://core/combat/battle.gd").new(data, 42, 0, ["lira", "noa"])
		combat.hand = [id]
		for member in combat.team:
			member.health -= 10
			member.stress = 6
		var card: Dictionary = combat.card_data(id)
		var owner = combat.character(card.owner)
		var energy: int = owner.energy
		var target: String = "lira" if card.target == "ally" else card.target
		var health: int = combat.character("lira").health
		var block: int = combat.character("lira").block
		combat.play(0, target)
		check(owner.energy == energy - int(card.cost) and not id in combat.hand, "Carta nueva jugable y con coste aplicado: " + id)
		var correct := false
		match id:
			"estocada": correct = combat.enemy_health == int(combat.enemy.health) - 13 - owner.stat("attack")
			"paso_bruma": correct = combat.character("lira").block == block + 5 and combat.hand.size() == 1
			"respiro": correct = combat.character("lira").stress == 2 and id in combat.exhausted
			"farol": correct = combat.character("lira").block == block + 7 and combat.character("lira").stress == 4
			"marea": correct = combat.character("lira").health == health + 9
			"eco_reflejado": correct = combat.enemy_health == int(combat.enemy.health) - 8 - owner.stat("attack") and id in combat.exhausted
		check(correct, "Efectos reales de carta nueva: " + id)
	var enemy_test = preload("res://core/combat/battle.gd").new(data, 42, 3, ["lira", "noa"])
	check(enemy_test.enemy.id == "espinero" and enemy_test.intent.amount == 5, "Nuevo enemigo anuncia ataque")
	enemy_test.end_turn()
	enemy_test.end_turn()
	check(enemy_test.enemy_block == 5, "Espinero ejecuta guardia de su patrón")
	Autoplay.fight(enemy_test)
	check(enemy_test.result == "Victoria", "Vencer al enemigo nuevo con cartas reales")
	var custom := config.duplicate(true)
	custom.route_nodes = Route.generate(42, config)
	for node in custom.route_nodes:
		node.erase("biome")
		if node.type != "boss":
			node.type = "reward"
			node.enemy = ""
	check(Validator.configuration(data, custom).is_empty(), "Ruta personalizada compatible con biomas")
	var model = Expedition.new(data, custom, 42, ["lira", "noa"])
	for row in range(4):
		var gold: int = model.gold
		check(model.enter(model.available()[0]) and model.phase == "reward", "Tesoro accesible")
		check(model.gold == gold + int(config.combat_gold), "Tesoro no recibe oro de victoria de reliquias")
		var offers: Array = model.offers.filter(func(offer): return offer.action == "relic")
		check(offers.size() == 1 and not offers[0].id in model.relic_ids, "Oferta de reliquia nueva sin duplicados")
		check(Validator.validate(model.export_state()).is_empty(), "Estado de recompensas ampliadas válido")
		var before: Dictionary = canonical(model.export_state())
		check(not model.choose("relic", "desconocida") and canonical(model.export_state()) == before, "Rechazar reliquia ajena sin mutar")
		var id: String = offers[0].id
		check(model.choose("relic", id) and id in model.relic_ids, "Adquirir reliquia mediante recompensa")
		check(not model.choose("relic", id), "No repetir la adquisición fuera de fase")
	check(model.relic_ids.size() == 4, "Cuatro reliquias únicas adquiridas")
	var total := Relics.bonuses(config, model.relic_ids)
	check(total.turn_block == 1 and total.turn_energy == 1 and total.victory_heal == 3 and total.victory_gold == 5, "Bonificaciones acumuladas correctas")
	check(model.combat_content().characters[0].energy == int(data.characters[0].energy) + 1, "Energía de reliquia llega al contenido de combate")
	check(model.combat_content().characters[0].passive.start_block == int(data.characters[0].passive.start_block) + 1, "Escudo de reliquia se añade a pasiva")
	model.party.lira.health -= 7
	model.party.noa.health = 0
	check(model.enter("4_0") and model.phase == "combat", "Entrar al jefe con reliquias")
	check(model.battle.character("lira").energy == int(data.characters[0].energy) + 1 and model.battle.character("lira").block == int(data.characters[0].passive.start_block) + 1, "Combate aplica energía y escudo al iniciar turno")
	check(model.battle.character("noa").energy == 0, "Reliquias no activan personajes caídos")
	check(Validator.validate(model.export_state()).is_empty(), "Combate con reliquias válido para guardar")
	check(Store.write(PATH, model.export_state()) == "", "Guardar combate con reliquias")
	var saved := Store.read(PATH)
	check(saved.has("state"), "Leer guardado ampliado")
	var restored = Expedition.restore(saved.state)
	check(canonical(restored.export_state()) == canonical(model.export_state()), "Restauración exacta con biomas, reliquias y RNG")
	for game in [model, restored]:
		game.battle.end_turn()
		game.sync_party()
	check(canonical(restored.export_state()) == canonical(model.export_state()), "Continuación idéntica sin aplicar dos veces las pasivas")
	# Fixture de transición: verificar el efecto de victoria sin depender de una estrategia de combate.
	model.battle.enemy_health = 0
	model.battle.result = "Victoria"
	var health: int = model.battle.character("lira").health
	var gold: int = model.gold
	check(model.finish_battle() and model.phase == "victory", "Victoria final con reliquias")
	check(model.party.lira.health == mini(int(data.characters[0].health), health + 3) and model.party.noa.health == 0, "Curación de victoria limitada y sin resurrección")
	check(model.gold == gold + 5 and not model.finish_battle(), "Oro de victoria se aplica una sola vez")
	check(Validator.validate(model.export_state()).is_empty(), "Victoria ampliada guardable")
	var event_config := config.duplicate(true)
	event_config.route_nodes = Route.generate(42, config)
	for node in event_config.route_nodes:
		if node.type != "boss": node.type = "event"
	var event_model = Expedition.new(data, event_config, 88, ["noa"])
	for row in range(4):
		check(event_model.enter(event_model.available()[0]), "Evento de bioma accesible")
		check(event_model.event_id in event_model.active_biome().events, "Evento elegido pertenece al bioma")
		if row >= 2:
			var choice: Dictionary = event_model.active_event().choices[0]
			check(not event_model.event_choice_enabled(choice) and not event_model.choose("event_choice", choice.id), "Carta de Lira no se concede a equipo solo de Noa")
		check(event_model.choose("event_choice", "heal"), "Decisión de recuperación funciona en cada bioma")
	var bad_configs: Array[Dictionary] = []
	var bad := config.duplicate(true)
	bad.biomes[1].first_row = 1
	bad_configs.append(bad)
	bad = config.duplicate(true)
	bad.biomes[0].last_row = 0
	bad_configs.append(bad)
	bad = config.duplicate(true)
	bad.biomes[0].encounters = ["no_existe"]
	bad_configs.append(bad)
	bad = config.duplicate(true)
	bad.biomes[0].events = ["no_existe"]
	bad_configs.append(bad)
	bad = config.duplicate(true)
	bad.relics[0].turn_energy = 999
	bad_configs.append(bad)
	bad = config.duplicate(true)
	bad.relics.append(bad.relics[0])
	bad_configs.append(bad)
	bad = config.duplicate(true)
	bad.biomes[0] = {}
	bad_configs.append(bad)
	for invalid in bad_configs: check(not Validator.configuration(data, invalid).is_empty(), "Rechazar configuración inválida de expansión")
	var invalid_state: Dictionary = restored.export_state()
	invalid_state.relics.append(invalid_state.relics[0])
	check(not Validator.validate(invalid_state).is_empty(), "Rechazar reliquias duplicadas en guardado")
	invalid_state = restored.export_state()
	invalid_state.relics[0] = "no_existe"
	check(not Validator.validate(invalid_state).is_empty(), "Rechazar reliquia desconocida en guardado")
	invalid_state = restored.export_state()
	invalid_state.erase("relics")
	check(not Validator.validate(invalid_state).is_empty(), "Rechazar inventario ausente en partida moderna")
	var foreign: RpgRunDefinition = rules.duplicate(false)
	foreign.biomes = rules.biomes.duplicate()
	foreign.biomes[0] = rules.biomes[0].duplicate(false)
	foreign.biomes[0].encounters = rules.biomes[0].encounters.duplicate()
	foreign.biomes[0].encounters[0] = foreign.biomes[0].encounters[0].duplicate(false)
	check(not Validator.resource_configuration(catalog, foreign).is_empty(), "Detectar enemigo clonado sin registrar en bioma")
	var relic_copy := Factory.plan("relic", "concha_copia", "Copia", catalog, rules, rules.relics[0])
	check(relic_copy.errors.is_empty() and relic_copy.rules.relics.size() == 5, "Asistente duplica y registra reliquia")
	relic_copy.resource.turn_block = 2
	check(rules.relics[0].turn_block == 1, "Duplicar reliquia no muta original")
	var biome_copy := Factory.plan("biome", "ruinas_copia", "Copia", catalog, rules, rules.biomes[0])
	check(biome_copy.errors.is_empty() and biome_copy.rules.biomes.size() == 2, "Bioma se duplica inactivo sin solapar tramos")
	biome_copy.resource.encounters.clear()
	check(not rules.biomes[0].encounters.is_empty(), "Pools de bioma duplicados son independientes")
	var legacy_path := PATH + ".legacy"
	var next_path := PATH + ".next"
	check(DirAccess.copy_absolute(ProjectSettings.globalize_path("res://tests/fixtures/phase6_combat.json"), ProjectSettings.globalize_path(legacy_path)) == OK, "Copiar fixture sin modificar el original")
	check(DirAccess.copy_absolute(ProjectSettings.globalize_path("res://tests/fixtures/phase6_next_turn.json"), ProjectSettings.globalize_path(next_path)) == OK, "Copiar continuación congelada")
	var edited: RpgRunDefinition = rules.duplicate(false)
	edited.biomes = rules.biomes.duplicate()
	edited.relics = rules.relics.duplicate()
	edited.biomes[0] = rules.biomes[0].duplicate(false)
	edited.relics[0] = rules.relics[0].duplicate(false)
	edited.biomes[0].color = Color("ffbb77")
	edited.relics[0].turn_block = 2
	check(ResourceSaver.save(edited, PATH + ".rules.tres") == OK, "Guardar modificaciones de bioma y reliquia en Resources")
	var loaded_rules: RpgRunDefinition = ResourceLoader.load(PATH + ".rules.tres", "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	check(canonical(loaded_rules.to_dict()) == canonical(edited.to_dict()), "Ediciones tipadas sobreviven guardar y recargar")
	var edited_model = Expedition.new(data, loaded_rules.to_dict(), 42, ["lira", "noa"])
	edited_model.relic_ids = ["concha"]
	check(edited_model.active_biome().color == "ffbb77" and edited_model.combat_content().characters[0].passive.start_block == int(data.characters[0].passive.start_block) + 2, "Cambios del editor llegan al juego")
	var exhausted_config := custom.duplicate(true)
	exhausted_config.rewards.card_choices = 0
	exhausted_config.rewards.upgrade_choices = 0
	exhausted_config.rewards.allow_skip = false
	var exhausted_model = Expedition.new(data, exhausted_config, 42, ["lira", "noa"])
	exhausted_model.relic_ids = config.relics.map(func(relic): return relic.id)
	exhausted_model.enter("0_0")
	check(exhausted_model.offers == [{"action": "skip", "id": ""}], "Pool de reliquias agotado conserva una salida segura")
	var old := Store.read(legacy_path)
	var expected := Store.read(next_path)
	check(old.has("state") and expected.has("state"), "Leer instantáneas reales de fase 6")
	var legacy = Expedition.restore(old.state)
	check(not legacy.config.has("biomes") and not legacy.export_state().has("relics") and legacy.content.cards.size() == 14, "Partida anterior mantiene contenido, formato y reglas antiguos")
	check(canonical(legacy.export_state()) == canonical(old.state), "Restauración exacta de partida antigua congelada")
	legacy.battle.end_turn()
	legacy.sync_party()
	check(canonical(legacy.export_state()) == canonical(expected.state), "Siguiente turno conserva el RNG y comportamiento de fase 6")
	var route_editor = load("res://tools/editor/route_dialog.gd").new()
	root.add_child(route_editor)
	route_editor.open_for(catalog, rules)
	var first_enemy: OptionButton = route_editor.graph.get_node("0_0").get_child(0).get_child(1)
	var first_pool: Array = []
	for index in range(first_enemy.item_count):
		var resource = first_enemy.get_item_metadata(index)
		if resource != null: first_pool.append(resource.id)
	check(first_pool == ["eco", "susurro"], "Editor de rutas filtra enemigos por bioma")
	check(route_editor.graph.get_node("0_0").get_child(0).get_child(3).text.contains("Ruinas"), "Editor identifica bioma sin ensanchar títulos de nodos")
	route_editor.queue_free()
	await process_frame
	var main = load("res://scenes/main.tscn").instantiate()
	main.save_path = PATH + ".scene"
	root.add_child(main)
	await process_frame
	main._new_expedition("42")
	check(main.run_ui.get_node("%Biome").text.contains("Ruinas") and main.run_ui.get_node("%Relics").text.contains("ninguna"), "UI muestra bioma e inventario vacío")
	var base_environment = main.arena.base_environment
	check(main.arena.get_node("WorldEnvironment").environment != base_environment, "Bioma aplica entorno visual independiente")
	var ui_model = Expedition.new(data, custom, 42, ["lira", "noa"])
	main.run = ui_model
	main._enter_node("0_0")
	var options = main.run_ui.get_node("%Choices")
	var relic_button: Button
	for button in options.get_children():
		if button.text.begins_with("Reliquia"): relic_button = button
	check(relic_button != null, "Recompensa de reliquia tiene botón de escena")
	if relic_button != null: relic_button.pressed.emit()
	check(main.run.relic_ids.size() == 1 and main.run_ui.get_node("%Relics").text.contains(main.run.relic_description(main.run.relic_ids[0])), "Botón adquiere reliquia y actualiza inventario")
	main._menu()
	check(main.arena.get_node("WorldEnvironment").environment == base_environment, "Volver al menú restaura escenario editado")
	main.queue_free()
	await process_frame
	for seed_value in [42, 88]:
		var full = Expedition.new(data, config, seed_value, ["lira", "noa"])
		for step in range(12):
			if full.phase in ["victory", "defeat"]: break
			if full.phase == "map":
				var target: String = full.available()[0]
				for id in full.available():
					if full.node(id).type in ["combat", "rest"]: target = id
				full.enter(target)
			if full.phase == "combat":
				Autoplay.fight(full.battle)
				full.sync_party()
				full.finish_battle()
			if full.phase == "reward":
				var chosen: Dictionary = full.offers[-1]
				for offer in full.offers:
					if offer.action == "relic": chosen = offer
				full.choose(chosen.action, chosen.id)
			elif full.phase in ["rest", "event"]: full.choose("heal")
			elif full.phase == "shop": full.choose("leave")
			check(Validator.validate(full.export_state()).is_empty(), "Expedición completa conserva estado válido")
		check(full.phase == "victory" and not full.relic_ids.is_empty(), "Completar dos biomas y jefe con cartas reales y reliquias")
	check(data == initial_data and config == initial_config and catalog.to_dict() == initial_data and rules.to_dict() == initial_config, "Pruebas no alteran datos originales")
	for suffix in ["", ".bak", ".tmp", ".legacy", ".next", ".rules.tres", ".scene", ".scene.bak", ".scene.tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	print("EXPANSIÓN: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)
