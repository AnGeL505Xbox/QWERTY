extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._start()
	await process_frame
	scene._select(0)
	var target: String = scene.battle.valid_targets(0)[0]
	scene._confirm(target)
	scene._end_turn()
	await process_frame
	scene._menu()
	scene._choose_enemy(1)
	scene._select(0)
	scene._cancel()
	await create_timer(0.5).timeout
	print("ESCENA: menú, combate, carta, turno y reinicio completados")
	scene.queue_free()
	await process_frame
	quit()
