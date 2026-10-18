extends Node3D

const Actor = preload("res://visuals/animations/actor.gd")
const Feedback = preload("res://visuals/effects/feedback.gd")
const Profile = preload("res://visuals/animations/profile.gd")
var actors: Dictionary = {}
var enemy_view: Node3D
var feedback: Node3D
var profiles: Dictionary
var outcome := ""
var camera: Camera3D
var elapsed := 0.0
var motion_enabled := true

func _ready() -> void:
	profiles = JSON.parse_string(FileAccess.get_file_as_string("res://visuals/profiles/catalog.json"))
	camera = Camera3D.new()
	camera.position = Vector3(0, 3.4, 10)
	camera.look_at_from_position(camera.position, Vector3(0, 0.6, 0))
	camera.fov = 48
	add_child(camera)
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("10182f")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("91a5c8")
	environment.ambient_light_energy = 0.65
	world.environment = environment
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-60, -30, 0)
	light.shadow_enabled = false
	add_child(light)
	_box(Vector3(14, 0.2, 7), Vector3(0, -0.8, -1), Color("242d48"))
	# Capas a distinta profundidad producen paralaje con la deriva de cámara.
	for i in range(7):
		_box(Vector3(0.32, 5.8, 0.5), Vector3(-7.2 + i * 2.4, 1.6, -5), Color("252c47"))
		_box(Vector3(0.10, 4.8, 0.12), Vector3(-7.2 + i * 2.4, 1.8, -4.7), Color("537486"), true)
	for i in range(5):
		var crystal := _box(Vector3(0.45, 1.5, 0.45), Vector3(-5.2 + i * 2.6, -0.05, -2.6), Color("5d6486"))
		crystal.rotation_degrees.z = 22
	_box(Vector3(11, 0.025, 0.04), Vector3(0, -0.68, 1.4), Color("67b3c4"), true)
	feedback = Feedback.new()
	add_child(feedback)

func _process(delta: float) -> void:
	elapsed += delta
	if camera != null:
		camera.position.x = sin(elapsed * 0.18) * 0.10 if motion_enabled else 0.0

func _box(size_value: Vector3, at: Vector3, color: Color, unshaded: bool = false) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	instance.mesh = mesh
	instance.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	instance.material_override = material
	add_child(instance)
	return instance

func _profile(id: String, tint: Color) -> Resource:
	var path := str(profiles.get(id, ""))
	if not path.is_empty() and ResourceLoader.exists(path):
		var resource = load(path)
		if resource != null and resource.get_script() == Profile:
			return resource
	var fallback := Profile.new()
	fallback.texture = load("res://visuals/traveler.svg")
	fallback.tint = tint
	return fallback

func set_team(team: Array) -> void:
	feedback.clear()
	outcome = ""
	for actor in actors.values():
		remove_child(actor)
		actor.queue_free()
	actors.clear()
	for i in range(team.size()):
		var member = team[i]
		var actor := Actor.new()
		actor.position = Vector3(-3.7 + i * 1.2, 0.5, i * 0.25)
		add_child(actor)
		actor.setup(member.id, member.definition.name, _profile(member.id, Color(member.definition.color)))
		actors[member.id] = actor
		actor.play_animation("enter")

func set_enemy(enemy: Dictionary) -> void:
	if enemy_view != null:
		remove_child(enemy_view)
		enemy_view.queue_free()
	enemy_view = Actor.new()
	enemy_view.position = Vector3(2.9, 0.5, -0.3)
	add_child(enemy_view)
	enemy_view.setup("enemy", enemy.name, _profile(enemy.id if profiles.has(enemy.id) else "enemy", Color("ef78ab")))
	enemy_view.play_animation("enter")

func _actor(id: String):
	return enemy_view if id == "enemy" else actors.get(id)

func highlight_targets(ids: Array) -> void:
	for id in actors:
		actors[id].highlight(id in ids)
	if enemy_view != null:
		enemy_view.highlight("enemy" in ids)

func on_combat_event(event: Dictionary) -> void:
	var source = _actor(event.source)
	if source != null:
		source.play_animation(event.animation)
		if event.animation in ["crisis", "special"]:
			feedback.show_at(source.position, "CRISIS" if event.animation == "crisis" else "ESPECIAL", Color("dcaff0"))
	for change in event.changes:
		var target = _actor(change.target)
		if target == null:
			continue
		var pieces: Array[String] = []
		var color := Color("9de6ef")
		if change.health < 0:
			pieces.append("%d PV" % change.health)
			target.play_animation("hurt")
			color = Color("ff8fa9")
		elif change.health > 0:
			pieces.append("+%d PV" % change.health)
			color = Color("a3f0bc")
		if change.shield != 0:
			pieces.append("%+d escudo" % change.shield)
			if change.shield > 0:
				target.play_animation("defend")
		if change.stress != 0:
			pieces.append("%+d estrés" % change.stress)
		if change.status != "":
			pieces.append(change.status)
		if not pieces.is_empty():
			var text := " · ".join(pieces)
			target.last_feedback = text
			feedback.show_at(target.position, text, color)

func update_team(team: Array) -> void:
	for member in team:
		if actors.has(member.id):
			actors[member.id].show_state(member.health, member.max_health, member.block, member.stress)

func sync_battle(battle) -> void:
	update_team(battle.team)
	if enemy_view != null:
		enemy_view.show_state(battle.enemy_health, int(battle.enemy.health), battle.enemy_block)
	if outcome == "" and battle.result != "":
		outcome = battle.result
		for member in battle.living():
			actors[member.id].play_animation("victory" if outcome == "Victoria" else "defeat")
		if outcome == "Derrota" and enemy_view != null:
			enemy_view.play_animation("victory")
