extends SceneTree

const Catalog = preload("res://core/data/catalog.gd")
const Expedition = preload("res://core/progression/expedition.gd")
const Validator = preload("res://core/save_system/run_validator.gd")
const Store = preload("res://core/save_system/store.gd")
var checks := 0
var failures := 0
const PATH = "user://test_roguelike.json"

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		push_error(message)
		failures += 1

func fresh(seed_value: int = 42):
	return Expedition.new(Catalog.load_content(), load("res://data/progression/expedition.tres").to_dict(), seed_value, ["lira", "noa"])

func canonical(value):
	return JSON.parse_string(JSON.stringify(value))

func check_state(run, message: String) -> void:
	var errors := Validator.validate(run.export_state())
	check(errors.is_empty(), message + ": " + str(errors))

func win_fixture(run) -> void:
	# Solo para probar transiciones; la expedición completa de abajo usa cartas y turnos reales.
	run.battle.enemy_health = 0
	run.battle.result = "Victoria"
	run.sync_party()
	run.finish_battle()

func _initialize() -> void:
	var rules: RpgRunDefinition = load("res://data/progression/expedition.tres").duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	rules.rows = 6
	rules.starting_gold = 7
	check(ResourceSaver.save(rules, PATH + ".tres") == OK, "Guardar configuración editable")
	var loaded_rules: RpgRunDefinition = ResourceLoader.load(PATH + ".tres", "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	var configured = Expedition.new(Catalog.load_content(), loaded_rules.to_dict(), 42, ["lira", "noa"])
	check(configured.nodes.size() == 11 and configured.gold == 7, "Configuración visual guardada llega a la expedición")
	var run = fresh()
	check_state(run, "Estado inicial válido")
	check(run.nodes == fresh().nodes, "Mapa reproducible")
	check(run.nodes != fresh(88).nodes, "Semillas diferentes generan encuentros distintos")
	check(run.nodes.size() == 9 and run.available() == ["0_0", "0_1"], "Mapa de cinco etapas")
	check(not run.enter("4_0"), "No saltar al jefe")
	check(run.enter("0_0") and run.phase == "combat", "Entrada a combate")
	check_state(run, "Combate válido")
	var initial := run.export_state()
	check(Store.write(PATH, initial) == "", "Guardar combate")
	var loaded := Store.read(PATH)
	check(loaded.has("state"), "Leer combate")
	if not loaded.has("state"):
		quit(1)
		return
	var resumed = Expedition.restore(loaded.state)
	check(canonical(initial) == canonical(resumed.export_state()), "Restauración exacta de combate y RNG")
	for model in [run, resumed]:
		var index := -1
		for i in range(model.battle.hand.size()):
			if not model.battle.valid_targets(i).is_empty():
				index = i
				break
		if index >= 0:
			model.battle.play(index)
		model.battle.end_turn()
		model.sync_party()
	check(canonical(run.export_state()) == canonical(resumed.export_state()), "Continuación idéntica tras cargar")
	win_fixture(run)
	check_state(run, "Recompensas válidas")
	var gold: int = run.gold
	check(not run.finish_battle() and run.gold == gold, "No duplicar oro por resultado")
	var upgrade_offers: Array = run.offers.filter(func(offer): return offer.action == "upgrade")
	check(not upgrade_offers.is_empty(), "Se ofrecen mejoras")
	var upgrade_id: String = upgrade_offers[0].id
	check(run.choose("upgrade", upgrade_id) and run.phase == "map", "Elegir mejora")
	check(run.upgrades[upgrade_id] == 1 and not run.choose("upgrade", upgrade_id), "Recompensa solo una vez")
	var original: Dictionary = run.card(upgrade_id)
	var improved: Dictionary = run.combat_content().cards.filter(func(card): return card.id == upgrade_id)[0]
	check(improved.effects[0].amount == int(original.effects[0].amount) + 2, "Mejora cambia efectos sin modificar el catálogo base")
	check_state(run, "Mapa después de recompensa")
	check(not run.enter("0_0"), "No repetir nodo")
	var middle: String = run.available()[0]
	run.enter(middle)
	if run.phase == "combat":
		win_fixture(run)
	if run.phase == "reward":
		var offer: Dictionary = run.offers[0]
		var count := _deck_size(run)
		run.choose(offer.action, offer.id)
		check(_deck_size(run) == count + 1, "Recompensa añade una copia al mazo")
	elif run.phase == "shop":
		run.choose("leave")
	elif run.phase in ["rest", "event"]:
		run.choose("heal")
	check(run.phase == "map", "Resolución de nodo intermedio")
	check(run.enter("2_1") and run.phase == "shop", "Tienda accesible")
	var offered: String = run.offers[0].id
	gold = run.gold
	check(run.choose("card", offered) and run.gold == gold - int(run.config.card_price), "Compra paga oro")
	check(not run.choose("card", offered), "Oferta comprada no se repite")
	run.gold = 0
	check(not run.choose("upgrade", upgrade_id) and run.gold == 0, "No comprar sin oro")
	check_state(run, "Tienda tras compras")
	check(Store.write(PATH, run.export_state()) == "", "Guardar tienda")
	var corrupted := FileAccess.open(PATH, FileAccess.WRITE)
	corrupted.store_string("{incompleto")
	corrupted.close()
	var recovered := Store.read(PATH)
	check(recovered.has("state") and recovered.has("warning"), "Recuperar copia tras corrupción")
	var before_invalid := FileAccess.get_file_as_string(PATH)
	var bad: Dictionary = run.export_state()
	bad.gold = -1
	check(Store.write(PATH, bad) != "" and FileAccess.get_file_as_string(PATH) == before_invalid, "No sobrescribir con estado inválido")
	check(Store.write(PATH, run.export_state()) == "" and Store.read(PATH).has("state"), "Conservar archivo dañado y volver a guardar")
	for key in ["party", "content", "nodes", "battle", "config", "team"]:
		bad = run.export_state()
		bad[key] = null
		check(not Validator.validate(bad).is_empty(), "Rechazar campo dañado " + key)
	bad = run.export_state()
	bad.content.characters[0].deck = null
	check(not Validator.validate(bad).is_empty(), "Rechazar estructura anidada dañada")
	bad = run.export_state()
	bad.nodes[0].links = ["4_0"]
	check(not Validator.validate(bad).is_empty(), "Rechazar enlaces alterados")
	bad = initial.duplicate(true)
	bad.battle.hand.append("desconocida")
	check(not Validator.validate(bad).is_empty(), "Rechazar pilas alteradas")
	var rest = fresh(7)
	rest.enter("0_0")
	win_fixture(rest)
	rest.choose("skip")
	rest.enter(rest.available()[0])
	if rest.phase == "combat":
		win_fixture(rest)
	if rest.phase == "reward": rest.choose("skip")
	elif rest.phase == "shop": rest.choose("leave")
	elif rest.phase in ["event", "rest"]: rest.choose("heal")
	rest.enter("2_0")
	rest.party.lira.health = 30
	rest.party.lira.stress = 9
	rest.party.noa.health = 0
	check(rest.choose("heal") and rest.party.lira.health == 38 and rest.party.lira.stress == 3 and rest.party.noa.health == 0, "Descanso cura y alivia sin resurrección")
	check_state(rest, "Descanso conserva equipo válido")
	var event_rules: Dictionary = load("res://data/progression/expedition.tres").to_dict()
	event_rules.middle_types = ["event"]
	var event_run = Expedition.new(Catalog.load_content(), event_rules, 5, ["lira", "noa"])
	event_run.enter("0_0")
	win_fixture(event_run)
	event_run.choose("skip")
	event_run.enter("1_0")
	check(event_run.phase == "event", "Evento configurable accesible")
	event_run.party.lira.health = 2
	event_run.party.noa.health = 0
	gold = event_run.gold
	check(event_run.choose("risk") and event_run.phase == "defeat" and event_run.gold == gold + int(event_rules.event_gold), "Riesgo de evento puede terminar la expedición")
	check_state(event_run, "Derrota de evento válida")
	var elite = fresh()
	elite.enter("0_0")
	win_fixture(elite)
	elite.choose("skip")
	elite.enter(elite.available()[0])
	if elite.phase == "combat": win_fixture(elite)
	if elite.phase == "reward": elite.choose("skip")
	elif elite.phase == "shop": elite.choose("leave")
	elif elite.phase in ["rest", "event"]: elite.choose("heal")
	elite.enter("2_0")
	elite.choose("heal")
	elite.enter("3_0")
	check(elite.battle.enemy_health == int(elite.content.enemies.filter(func(enemy): return enemy.id == elite.battle.enemy.id)[0].health) + 12, "Élite aplica bonificación de vida")
	check_state(elite, "Élite válida")
	gold = elite.gold
	win_fixture(elite)
	check(elite.gold == gold + int(elite.config.combat_gold) + int(elite.config.elite_gold_bonus), "Élite concede oro adicional")
	check_state(elite, "Recompensa de élite válida")
	check(Validator.resource_configuration(load("res://data/catalog.tres"), load("res://data/progression/expedition.tres")).is_empty(), "Configuración Resources válida")
	var unregistered: RpgRunDefinition = load("res://data/progression/expedition.tres").duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	check(not Validator.resource_configuration(load("res://data/catalog.tres"), unregistered).is_empty(), "Rechazar encuentro clonado sin registrar su recurso")
	var bad_config: Dictionary = elite.config.duplicate(true)
	bad_config.encounters = ["no_existe"]
	check(not Validator.configuration(Catalog.load_content(), bad_config).is_empty(), "Encuentro desconocido bloquea nueva expedición")
	var future_path := PATH + ".future"
	var future := FileAccess.open(future_path, FileAccess.WRITE)
	future.store_string(JSON.stringify({"version": 99}))
	future.close()
	check(Store.read(future_path).has("error") and FileAccess.get_file_as_string(future_path).contains("99"), "Versión futura rechazada sin sobrescribir")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(future_path))
	var full = fresh(42)
	var encounters := 0
	for step in range(12):
		if full.phase in ["victory", "defeat"]: break
		if full.phase == "map":
			var choices: Array = full.available()
			var choice: String = choices[0]
			for id in choices:
				if full.node(id).type == "rest" or full.node(id).type == "combat": choice = id
			full.enter(choice)
		if full.phase == "combat":
			encounters += 1
			_fight(full.battle)
			full.sync_party()
			check_state(full, "Combate real terminado")
			full.finish_battle()
		if full.phase == "reward":
			var improvements: Array = full.offers.filter(func(offer): return offer.action == "upgrade")
			var offer: Dictionary = improvements[0] if not improvements.is_empty() else full.offers[-1]
			full.choose(offer.action, offer.id)
		elif full.phase in ["rest", "event"]: full.choose("heal")
		elif full.phase == "shop": full.choose("leave")
		check_state(full, "Progreso real válido")
	check(encounters >= 3 and full.phase == "victory", "Expedición real completa con cartas, turnos y jefe (fase: " + full.phase + ")")
	for name in DirAccess.get_files_at("user://"):
		if name.begins_with("test_roguelike.json"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path("user://" + name))
	print("ROGUELIKE: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)

func _deck_size(run) -> int:
	var size := 0
	for character in run.content.characters:
		if character.id in run.team_ids: size += character.deck.size()
	return size

func _fight(battle) -> void:
	preload("res://tests/support/autoplay.gd").fight(battle)
