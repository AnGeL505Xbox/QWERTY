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
		check(cycling.hand.size() + cycling.draw_pile.size() + cycling.discard.size() == 7, "Conservación del mazo y reciclado")
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
	print("PRUEBAS: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
