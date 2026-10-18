extends SceneTree

const Catalog = preload("res://core/data/catalog.gd")
const Battle = preload("res://core/combat/battle.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		push_error(message)
		failures += 1

func _initialize() -> void:
	var data := Catalog.load_content()
	data.team = ["lira"]
	var battle := Battle.new(data, 42)
	check(battle.hand.size() == 5, "Robo inicial")
	var same := Battle.new(data, 42)
	check(battle.hand == same.hand, "Semilla reproducible")
	check(not battle.play(-1), "Índice inválido")
	battle.hand = ["velo", "corte", "pulso"]
	check(battle.play(0) and battle.block == 6, "Escudo")
	check(battle.play(0) and battle.enemy_health == 25, "Daño")
	battle.health = 39
	check(battle.play(0) and battle.health == 40, "Curación limitada")
	battle.hand = ["corte"]
	check(not battle.play(0) and battle.hand.size() == 1, "Energía insuficiente")
	battle.end_turn()
	check(battle.health == 40 and battle.block == 0 and battle.energy == 3, "Escudo y nuevo turno")
	var cycling := Battle.new(data, 99)
	for i in range(20):
		cycling.health = cycling.max_health
		cycling.end_turn()
		check(cycling.hand.size() + cycling.draw_pile.size() + cycling.discard.size() == data.characters[0].deck.size(), "Conservación del mazo y reciclado")
	battle.hand = ["corte"]
	battle.enemy_health = 1
	battle.play(0)
	check(battle.result == "Victoria", "Victoria")
	var hp: int = battle.health
	battle.end_turn()
	check(battle.health == hp and not battle.play(0), "Combate cerrado")
	var loss := Battle.new(data)
	loss.health = 1
	loss.end_turn()
	check(loss.result == "Derrota", "Derrota")
	var tactical := Battle.new(data, 42)
	tactical.hand = ["corte"]
	check(tactical.valid_targets(0) == ["enemy"], "Objetivo de ataque")
	check(not tactical.play(0, "self") and tactical.energy == 3 and tactical.enemy_health == 32 and tactical.hand.size() == 1, "Objetivo incorrecto sin mutaciones")
	tactical.enemy_block = 5
	check(tactical.play(0, "enemy") and tactical.enemy_health == 30 and tactical.enemy_block == 0, "Absorción parcial por escudo enemigo")
	tactical.hand = ["reserva", "lectura"]
	tactical.energy = 0
	check(tactical.play(0, "self") and tactical.energy == 2 and tactical.exhausted == ["reserva"], "Energía y agotamiento")
	tactical.draw_pile = ["corte"]
	tactical.discard = ["velo"]
	check(tactical.play(0, "self") and tactical.hand.size() == 2 and not "lectura" in tactical.hand, "Robo recicla sin recuperar la carta en resolución")
	check(not "reserva" in tactical.hand and not "reserva" in tactical.draw_pile and not "reserva" in tactical.discard, "Agotada fuera de circulación")
	var guard := Battle.new(data, 4, 1)
	check(guard.intent.type == "guard" and guard.intent.amount == 8, "Intención inicial configurada")
	guard.end_turn()
	check(guard.health == 40 and guard.enemy_block == 8 and guard.intent.type == "attack", "Guardia sin daño y siguiente intención")
	guard.hand = ["corte"]
	guard.play(0, "enemy")
	check(guard.enemy_health == 42 and guard.enemy_block == 1, "Absorción completa")
	guard.end_turn()
	check(guard.health == 30 and guard.enemy_block == 0 and guard.intent.type == "guard", "Ataque anunciado y expiración de escudo")
	var healer := Battle.new(data, 1, 2)
	healer.end_turn()
	healer.enemy_health = 27
	healer.end_turn()
	check(healer.enemy_health == 28 and healer.intent.amount == 8, "Curación enemiga limitada y patrón")
	var Effects = preload("res://core/effects/registry.gd")
	check(not Effects.valid({"type": "unknown", "amount": 1}, "self"), "Efecto desconocido rechazado")
	check(not Effects.valid({"type": "damage", "amount": -1}, "enemy"), "Magnitud negativa rechazada")
	check(not Effects.valid({"type": "damage", "amount": 1}, "self"), "Destino incompatible rechazado")
	var exhausted_battle := Battle.new(data, 123)
	for i in range(8):
		exhausted_battle.health = 40
		var reserve_index := exhausted_battle.hand.find("reserva")
		if reserve_index >= 0:
			exhausted_battle.play(reserve_index, "self")
		exhausted_battle.end_turn()
		check(exhausted_battle.hand.size() + exhausted_battle.draw_pile.size() + exhausted_battle.discard.size() + exhausted_battle.exhausted.size() == data.characters[0].deck.size(), "Conservación incluyendo agotamiento")
	print("PRUEBAS: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
