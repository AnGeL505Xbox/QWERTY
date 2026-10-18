extends Node3D

var actor: Sprite3D

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
	actor = _character(Vector3(-2.5, 0.5, 0), Color("69e3e4"))
	_character(Vector3(2.5, 0.5, -0.5), Color("ef78ab"))
	var idle := create_tween().set_loops()
	idle.tween_property(actor, "position:y", 0.65, 1.0)
	idle.tween_property(actor, "position:y", 0.5, 1.0)

func _character(at: Vector3, tint: Color) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = load("res://visuals/traveler.svg")
	sprite.pixel_size = 0.012
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.modulate = tint
	sprite.position = at
	add_child(sprite)
	return sprite

func animate(kind: String) -> void:
	var tween := create_tween()
	var tint := Color("ff7e97") if kind == "hurt" else Color.WHITE
	tween.tween_property(actor, "modulate", tint, 0.12)
	tween.tween_property(actor, "modulate", Color("69e3e4"), 0.25)
