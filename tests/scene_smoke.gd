extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._start()
	await process_frame
	scene._play(0)
	scene.battle.end_turn()
	await process_frame
	scene._menu()
	scene._start()
	await create_timer(0.5).timeout
	print("ESCENA: menú, combate, carta, turno y reinicio completados")
	scene.queue_free()
	await process_frame
	quit()
