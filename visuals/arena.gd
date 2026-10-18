@tool
extends Node3D

const Profile = preload("res://visuals/animations/profile.gd")
var actors: Dictionary = {}
@onready var enemy_view: Node3D = $EnemySlot/Actor
@onready var feedback: Node3D = $Feedback
@export var profiles: Dictionary = {}
var outcome := ""
@onready var camera: Camera3D = $Camera3D
var camera_rest_x := 0.0
var elapsed := 0.0
@export var motion_enabled := true
@export_range(0, 0.5) var motion_amplitude := 0.1

func _ready() -> void:
	camera_rest_x = camera.position.x

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	elapsed += delta
	camera.position.x = camera_rest_x + (sin(elapsed * 0.18) * motion_amplitude if motion_enabled else 0.0)

func set_profiles(values: Dictionary) -> void:
	# Las definiciones visuales del catálogo tienen prioridad al iniciar un combate.
	profiles = profiles.duplicate()
	profiles.merge(values, true)

func _profile(id: String, tint: Color) -> Resource:
	var entry = profiles.get(id)
	if entry is RpgVisualProfile:
		return entry
	if entry is String and not entry.is_empty() and ResourceLoader.exists(entry):
		var resource = load(entry)
		if resource is RpgVisualProfile:
			return resource
	var fallback := Profile.new()
	fallback.texture = load("res://visuals/traveler.svg")
	fallback.tint = tint
	return fallback

func set_team(team: Array) -> void:
	feedback.clear()
	outcome = ""
	actors.clear()
	var slots := $AllySlots.get_children()
	assert(team.size() <= slots.size(), "Faltan posiciones de aliados en la escena")
	for i in range(slots.size()):
		var actor = slots[i].get_node("Actor")
		actor.reset_view()
		actor.visible = i < team.size()
		if i < team.size():
			var member = team[i]
			actor.setup(member.id, member.definition.name, _profile(member.id, Color(member.definition.color)))
			actors[member.id] = actor
			actor.play_animation("enter")

func set_enemy(enemy: Dictionary) -> void:
	enemy_view.setup("enemy", enemy.name, _profile(enemy.id if profiles.get(enemy.id) != null else "enemy", Color("ef78ab")))
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
			feedback.show_at(feedback.to_local(source.global_position), "CRISIS" if event.animation == "crisis" else "ESPECIAL", Color("dcaff0"))
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
			feedback.show_at(feedback.to_local(target.global_position), text, color)

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
