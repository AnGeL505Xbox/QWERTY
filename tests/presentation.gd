extends SceneTree

const Catalog = preload("res://core/data/catalog.gd")
const Battle = preload("res://core/combat/battle.gd")
const Actor = preload("res://visuals/animations/actor.gd")
const Profile = preload("res://visuals/animations/profile.gd")
const Arena = preload("res://visuals/arena.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		push_error(message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var profile := Profile.new()
	profile.frames = SpriteFrames.new() # Recurso sin fotogramas: debe usar el SVG de respaldo.
	for state in profile.durations:
		profile.durations[state] = 0.05
	var view = load("res://scenes/visuals/actor.tscn").instantiate()
	root.add_child(view)
	view.setup("prueba", "Nombre de prueba", profile)
	check(view.body.sprite_frames.has_animation("idle") and view.body.sprite_frames.get_frame_count("idle") == 1, "Respaldo sin spritesheet")
	for state in ["enter", "attack", "defend", "hurt", "special", "crisis"]:
		view.play_animation(state)
		check(view.current == state, "Inicia animación " + state)
		await view.active.finished
		await process_frame
		check(view.current == "idle" and view.pending.is_empty(), "Finaliza animación " + state)
	view.play_animation("desconocida")
	check(view.current == "idle", "Animación desconocida inocua")
	view.play_animation("attack")
	view.play_animation("idle")
	check(view.current == "idle" and view.pivot.position == Vector3.ZERO, "Reposo explícito cancela movimiento")
	for i in range(20):
		view.play_animation("defend")
	check(view.pending.size() <= 8, "Cola visual limitada")
	view.play_animation("idle")
	view.highlight(true)
	check(view.marker.visible, "Resaltado visual")
	view.play_animation("victory")
	await create_timer(0.15).timeout
	check(view.terminal and view.current == "victory", "Victoria persistente")
	view.play_animation("attack")
	check(view.current == "victory", "No sobreescribir estado final")
	var defeated = load("res://scenes/visuals/actor.tscn").instantiate()
	root.add_child(defeated)
	defeated.setup("caido", "Caído", profile)
	defeated.play_animation("hurt")
	defeated.show_state(0, 40, 0)
	await create_timer(0.25).timeout
	check(defeated.current == "defeat" and defeated.body.modulate.a < 0.3, "Daño seguido de derrota sin ocultación instantánea")
	check(not defeated.marker.visible, "Caído no resaltado")
	var native_profile := Profile.new()
	native_profile.frames = SpriteFrames.new()
	native_profile.frames.add_animation("golpe")
	native_profile.frames.add_frame("golpe", load("res://visuals/traveler.svg"))
	native_profile.animation_names = {"attack": "golpe"}
	var native_view = load("res://scenes/visuals/actor.tscn").instantiate()
	root.add_child(native_view)
	native_view.setup("native", "Native", native_profile)
	native_view.play_animation("attack")
	check(native_view.body.animation == "golpe", "Mapa de animación nativa")
	var data := Catalog.load_content()
	var battle := Battle.new(data, 14)
	var plain := Battle.new(data, 14)
	var arena = load("res://scenes/visuals/arena.tscn").instantiate()
	root.add_child(arena)
	arena.set_team(battle.team)
	arena.set_enemy(battle.enemy)
	battle.combat_event.connect(arena.on_combat_event)
	var events: Array = []
	battle.combat_event.connect(func(event): events.append(event))
	for model in [battle, plain]:
		model.hand = ["corte", "sutura", "destello"]
		model.character("lira").health = 38
		model.play(0, "enemy")
	check(battle.state_snapshot() == plain.state_snapshot(), "Reglas idénticas con y sin presentación")
	check(events[0].animation == "attack" and events[0].source == "lira", "Evento de ataque")
	check(events[0].changes[0].health == -7, "Daño real en evento")
	check(arena.enemy_view.last_feedback.contains("-7 PV"), "Feedback sobre enemigo")
	for model in [battle, plain]:
		model.play(0, "lira")
	check(arena.actors.lira.last_feedback.contains("+2 PV"), "Feedback de curación limitada sobre destinatario")
	for model in [battle, plain]:
		model.play(0, "enemy")
	check(events[-1].animation == "special", "Especial diferenciada de ataque")
	arena.highlight_targets(["noa"])
	check(arena.actors.noa.marker.visible and not arena.actors.lira.marker.visible and not arena.enemy_view.marker.visible, "Solo objetivos elegidos resaltados")
	for model in [battle, plain]:
		model.end_turn()
	check(events[-1].source == "enemy" and arena.actors.lira.last_feedback.contains("-6 PV"), "Ataque enemigo al destinatario")
	check(battle.state_snapshot() == plain.state_snapshot(), "Resultados independientes de animaciones pendientes")
	await create_timer(0.85).timeout
	check(arena.feedback.get_child_count() == 0, "Limpieza automática de efectos")
	for i in range(50):
		arena.feedback.show_at(Vector3.ZERO, "Prueba", Color.WHITE)
	check(arena.feedback.get_child_count() <= arena.feedback.MAX_EFFECTS, "Límite de efectos simultáneos")
	arena.set_team(battle.team)
	check(arena.feedback.get_child_count() == 0 and arena.actors.size() == 2, "Reinicio limpia efectos y actores")
	arena.feedback.enabled = false
	arena.feedback.show_at(Vector3.ZERO, "Desactivado", Color.WHITE)
	check(arena.feedback.get_child_count() == 0, "Efectos opcionales")
	arena.profiles["lira"] = "res://no_existe.tres"
	check(arena._profile("lira", Color.WHITE).texture != null, "Perfil ausente utiliza respaldo")
	for model in [battle, plain]:
		model.character("lira").stress = 10
		model.end_turn()
	check(events[-1].animation == "crisis" and battle.state_snapshot() == plain.state_snapshot(), "Evento de crisis sin alterar reglas")
	var snapshot := battle.state_snapshot()
	await create_timer(0.3).timeout
	check(snapshot == battle.state_snapshot(), "El tiempo visual no cambia el combate")
	battle.hand = ["corte"]
	battle.enemy_health = 1
	battle.character("lira").energy = 3
	battle.play(0, "enemy")
	arena.sync_battle(battle)
	check(arena.outcome == "Victoria" and arena.enemy_view.terminal and arena.actors.lira.terminal, "Resultado sincroniza victoria y derrota")
	for node in [view, defeated, native_view, arena]:
		node.queue_free()
	await process_frame
	print("PRESENTACIÓN: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)
