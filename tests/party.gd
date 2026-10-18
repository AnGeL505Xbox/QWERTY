extends SceneTree

const Catalog = preload("res://core/data/catalog.gd")
const Battle = preload("res://core/combat/battle.gd")
const Effects = preload("res://core/effects/registry.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		push_error(message)
		failures += 1

func _initialize() -> void:
	var data := Catalog.load_content()
	var battle := Battle.new(data, 42)
	var lira = battle.character("lira")
	var noa = battle.character("noa")
	check(battle.team.size() == 2 and noa.max_health == 34, "Dos personajes con estadísticas distintas")
	check(noa.block == 1 and lira.block == 0, "Pasiva de inicio de turno")
	check(battle.intent.target == "lira", "Objetivo enemigo anunciado")
	check(battle.hand.size() + battle.draw_pile.size() == 19, "Mazos individuales combinados")
	var same := Battle.new(data, 42)
	check(battle.hand == same.hand and battle.intent == same.intent, "Reproducibilidad del equipo")
	battle.hand = ["sutura", "calma", "impulso"]
	lira.health = 30
	lira.stress = 9
	check(battle.valid_targets(0) == ["lira", "noa"], "Curación permite elegir aliados vivos")
	check(not battle.play(0, "enemy") and noa.energy == 3, "Objetivo ajeno rechazado sin coste")
	check(battle.play(0, "lira") and lira.health == 35 and noa.energy == 2 and lira.energy == 3, "Paga el dueño y recibe el aliado")
	check(lira.stress == 9, "Curar no reduce estrés implícitamente")
	check(battle.play(0, "lira") and lira.stress == 3, "Carta de calma dirigida")
	check(battle.play(0, "lira") and lira.stat("attack") == 2, "Potenciación dirigida")
	battle.hand = ["corte"]
	battle.play(0, "enemy")
	check(battle.enemy_health == 23, "Ataque base más modificador del propietario")
	battle.end_turn()
	check(lira.statuses.strength == 1 and lira.stat("attack") == 2, "Estado dura hasta fin de ronda")
	battle.end_turn()
	check(not lira.statuses.has("strength") and lira.stat("attack") == 0, "Expiración de estado")
	noa.add_status("ward", 2)
	noa.add_status("ward", 1)
	check(noa.stat("defense") == 3 and noa.statuses.ward == 2, "Refrescar no acorta ni acumula magnitud")
	noa.block = 2
	var before: int = noa.health
	check(noa.receive_damage(7) == 2 and noa.health == before - 2 and noa.block == 0 and noa.stress == 2, "Defensa, escudo y estrés por daño real")
	noa.block = 8
	before = noa.stress
	check(noa.receive_damage(2) == 0 and noa.stress == before, "Daño absorbido no añade estrés")
	noa.block = 0
	noa.receive_damage(50)
	check(noa.stress == noa.definition.stress_limit and not noa.alive(), "Estrés limitado y caída")
	battle.hand = ["sutura", "corte"]
	check(battle.valid_targets(0).is_empty(), "No se juegan cartas de personajes caídos")
	check(battle.result.is_empty(), "Un aliado caído no implica derrota")
	var stress_battle := Battle.new(data, 4)
	var stressed = stress_battle.character("lira")
	stressed.stress = 10
	stress_battle.end_turn()
	check(stressed.crisis and stressed.energy == 2 and stressed.stress == 4, "Crisis reduce energía y alivia estrés")
	stress_battle.end_turn()
	check(not stressed.crisis and stressed.energy == 3, "La crisis no persiste sin umbral")
	var noa_only := Battle.new(data, 4, 0, ["noa"])
	var solo = noa_only.character("noa")
	solo.stress = 8
	solo.start_turn()
	check(solo.crisis and solo.energy == 1 and solo.stress == 3, "Respuesta psicológica individual")
	check(noa_only.intent.target == "noa" and noa_only.draw_pile.size() + noa_only.hand.size() == 7, "Selección de equipo modifica mazo y objetivo")
	noa_only.hand = ["eco_noa"]
	noa_only.play(0, "enemy")
	check(noa_only.enemy_health == 26, "Ataque propio de Noa")
	var fallen := Battle.new(data, 3)
	fallen.character("lira").health = 1
	fallen.end_turn()
	check(fallen.result.is_empty() and fallen.intent.target == "noa", "Retarget anunciado tras caída")
	fallen.hand = ["sutura"]
	check(fallen.valid_targets(0) == ["noa"], "No se pueden curar caídos")
	fallen.character("noa").health = 1
	fallen.character("noa").block = 0
	fallen.intent = {"type": "attack", "amount": 20, "target": "noa"}
	fallen.end_turn()
	check(fallen.result == "Derrota" and fallen.valid_targets(0).is_empty(), "Derrota de todo el equipo")
	var dead_health: int = fallen.character("noa").health
	fallen.end_turn()
	check(fallen.character("noa").health == dead_health, "Combate cerrado con equipo")
	check(same.character("lira").health == 40 and same.character("noa").statuses.is_empty(), "Estados de partidas independientes")
	check(not Effects.valid({"type":"status", "status":"ward", "amount":1.5}, "ally"), "Duración fraccionaria inválida")
	check(not Effects.valid({"type":"status", "status":"ward", "amount":0}, "ally"), "Duración nula inválida")
	var third_data: Dictionary = data.duplicate(true)
	var third: Dictionary = third_data.characters[0].duplicate(true)
	third.id = "tercero"
	third.name = "Personaje de prueba"
	third.deck = []
	for card in data.cards:
		if card.owner == "lira":
			var copy: Dictionary = card.duplicate(true)
			copy.id += "_test"
			copy.owner = third.id
			third_data.cards.append(copy)
	for id in data.characters[0].deck:
		third.deck.append(id + "_test")
	third.special += "_test"
	third_data.characters.append(third)
	var three := Battle.new(third_data, 3, 0, ["lira", "noa", "tercero"])
	check(three.team.size() == 3 and three.character("tercero").health == 40, "Tercer personaje sin duplicar lógica")
	three.hand = ["sutura"]
	check(three.valid_targets(0).size() == 3, "Tres objetivos aliados")
	var exhausted_team := Battle.new(data, 123)
	for i in range(20):
		for member in exhausted_team.team:
			member.health = member.max_health
		var index := exhausted_team.hand.find("reserva")
		if index >= 0:
			exhausted_team.play(index)
		exhausted_team.end_turn()
		check(exhausted_team.hand.size() + exhausted_team.draw_pile.size() + exhausted_team.discard.size() + exhausted_team.exhausted.size() == 19, "Conservación de mazos de equipo")
	print("PERSONAJES: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)
