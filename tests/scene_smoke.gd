extends SceneTree

var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._toggle_member("noa")
	check(scene.team_ids == ["lira"], "Retirar integrante")
	scene._toggle_member("lira")
	check(scene.team_ids == ["lira"], "Conservar al menos un integrante")
	scene._toggle_member("noa")
	scene._start()
	await process_frame
	check(scene.arena.actors.size() == 2, "Presentación del equipo")
	scene.battle.hand = ["sutura", "impulso"]
	scene.battle.character("lira").health = 30
	scene._select(0)
	scene._confirm("lira")
	check(scene.battle.health == 35 and scene.battle.character("noa").energy == 2, "Selección de aliado en escena")
	scene._select(0)
	scene._cancel()
	check(scene.selected == -1 and scene.battle.hand.size() == 1, "Cancelar sin consumir carta")
	scene._end_turn()
	await process_frame
	scene._menu()
	scene._toggle_member("lira")
	scene._choose_enemy(1)
	check(scene.battle.team.size() == 1 and scene.battle.team[0].id == "noa", "Nuevo combate con otro equipo")
	check(scene.battle.enemy.id == "custodio" and scene.arena.actors.size() == 1, "Cambio de enemigo y sprites")
	scene._select(0)
	scene._cancel()
	await create_timer(0.5).timeout
	print("ESCENA: selección de equipo, aliados, cancelación y reinicio; %d fallos" % failures)
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
