extends Node3D

var actors: Dictionary = {}
var actor_tweens: Dictionary = {}
var base_colors: Dictionary = {}

func _ready() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0, 4, 9)
	camera.rotation_degrees.x = -15
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 11
	add_child(camera)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-60, -30, 0)
	add_child(light)
	var floor_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(12, 0.2, 5)
	floor_mesh.mesh = box
	floor_mesh.position.y = -0.8
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("202a46")
	floor_mesh.material_override = material
	add_child(floor_mesh)
	_character(Vector3(2.5, 0.5, -0.5), Color("ef78ab"))

func set_team(team: Array) -> void:
	for tween in actor_tweens.values():
		if tween.is_valid():
			tween.kill()
	actor_tweens.clear()
	for sprite in actors.values():
		sprite.queue_free()
	actors.clear()
	base_colors.clear()
	for i in range(team.size()):
		var member = team[i]
		var tint := Color(member.definition.color)
		var sprite := _character(Vector3(-3.4 + i * 1.1, 0.5, i * 0.3), tint)
		actors[member.id] = sprite
		base_colors[member.id] = tint
		var idle := sprite.create_tween().set_loops()
		idle.tween_property(sprite, "position:y", 0.65, 1.0)
		idle.tween_property(sprite, "position:y", 0.5, 1.0)

func _character(at: Vector3, tint: Color) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = load("res://visuals/traveler.svg")
	sprite.pixel_size = 0.012
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.modulate = tint
	sprite.position = at
	add_child(sprite)
	return sprite

func animate_actor(actor_id: String, kind: String) -> void:
	if not actors.has(actor_id):
		return
	if actor_tweens.has(actor_id) and actor_tweens[actor_id].is_valid():
		actor_tweens[actor_id].kill()
	var sprite: Sprite3D = actors[actor_id]
	var tween := sprite.create_tween()
	actor_tweens[actor_id] = tween
	var tint := Color("ff7e97") if kind in ["hurt", "crisis"] else Color.WHITE
	tween.tween_property(sprite, "modulate", tint, 0.12)
	tween.tween_property(sprite, "modulate", base_colors[actor_id], 0.25)

func update_team(team: Array) -> void:
	for member in team:
		if actors.has(member.id):
			actors[member.id].visible = member.alive()
