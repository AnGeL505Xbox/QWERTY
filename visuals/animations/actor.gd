extends Node3D

const STATES = ["idle", "enter", "attack", "defend", "hurt", "special", "crisis", "victory", "defeat"]
var actor_id := ""
var display_name := ""
var profile: Resource
var pivot: Node3D
var body: AnimatedSprite3D
var name_label: Label3D
var marker: MeshInstance3D
var current := "idle"
var pending: Array[String] = []
var terminal := false
var active: Tween
var phase := 0.0
var last_feedback := ""

func setup(id: String, title: String, visual_profile: Resource) -> void:
	actor_id = id
	display_name = title
	profile = visual_profile
	pivot = Node3D.new()
	add_child(pivot)
	body = AnimatedSprite3D.new()
	body.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	body.pixel_size = profile.pixel_size
	body.modulate = profile.tint
	var has_frames := false
	if profile.frames != null:
		for animation_name in profile.frames.get_animation_names():
			if profile.frames.get_frame_count(animation_name) > 0:
				has_frames = true
	if has_frames:
		body.sprite_frames = profile.frames
	else:
		var frames := SpriteFrames.new()
		frames.rename_animation("default", "idle")
		frames.add_frame("idle", profile.texture if profile.texture != null else load("res://visuals/traveler.svg"))
		body.sprite_frames = frames
	pivot.add_child(body)
	name_label = Label3D.new()
	name_label.text = title
	name_label.position.y = 1.65
	name_label.font_size = 30
	name_label.pixel_size = 0.006
	add_child(name_label)
	marker = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.44
	ring.outer_radius = 0.50
	ring.rings = 16
	ring.ring_segments = 8
	marker.mesh = ring
	marker.position.y = -1.12
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("ffe5a0")
	marker.material_override = material
	marker.visible = false
	add_child(marker)
	_play_sprite("idle")

func _process(delta: float) -> void:
	phase += delta
	if current == "idle" and pivot != null:
		pivot.position.y = sin(phase * 2.5) * 0.045

func highlight(enabled: bool) -> void:
	marker.visible = enabled and not terminal

func play_animation(state: String) -> void:
	if not state in STATES or terminal:
		return
	if state == "idle":
		if active != null and active.is_valid():
			active.kill()
		pending.clear()
		current = "idle"
		pivot.position = Vector3.ZERO
		pivot.rotation = Vector3.ZERO
		pivot.scale = Vector3.ONE
		body.modulate = profile.tint
		_play_sprite("idle")
		return
	if state in ["victory", "defeat"]:
		terminal = true
		marker.visible = false
	if pending.size() >= 8:
		pending.pop_front()
	pending.append(state)
	if active == null or not active.is_running():
		_next()

func _play_sprite(state: String) -> void:
	var animation_name := str(profile.animation_names.get(state, state))
	if body.sprite_frames.has_animation(animation_name) and body.sprite_frames.get_frame_count(animation_name) > 0:
		body.play(animation_name)
	elif body.sprite_frames.has_animation("idle") and body.sprite_frames.get_frame_count("idle") > 0:
		body.play("idle")
	else:
		for available in body.sprite_frames.get_animation_names():
			if body.sprite_frames.get_frame_count(available) > 0:
				body.play(available)
				break

func _next() -> void:
	if pending.is_empty():
		if not terminal:
			current = "idle"
			_play_sprite("idle")
		return
	current = pending.pop_front()
	pivot.position = Vector3.ZERO
	pivot.rotation = Vector3.ZERO
	pivot.scale = Vector3.ONE
	body.modulate = profile.tint
	_play_sprite(current)
	var duration := maxf(0.05, float(profile.durations.get(current, 0.35)))
	active = create_tween()
	match current:
		"enter":
			pivot.position.x = -0.55 * profile.facing
			body.modulate.a = 0.1
			active.tween_property(pivot, "position:x", 0.0, duration)
			active.parallel().tween_property(body, "modulate:a", 1.0, duration)
		"attack":
			active.tween_property(pivot, "position:x", 0.5 * profile.facing, duration * 0.4)
			active.tween_property(pivot, "position:x", 0.0, duration * 0.6)
		"defend":
			active.tween_property(pivot, "scale", Vector3(1.08, 0.93, 1), duration * 0.4)
			active.tween_property(pivot, "scale", Vector3.ONE, duration * 0.6)
		"hurt":
			body.modulate = Color("ff668c")
			pivot.position.x = -0.18 * profile.facing
			active.tween_property(pivot, "position:x", 0.0, duration)
			active.parallel().tween_property(body, "modulate", profile.tint, duration)
		"special":
			active.tween_property(pivot, "position:y", 0.3, duration * 0.4)
			active.parallel().tween_property(body, "modulate", Color.WHITE, duration * 0.4)
			active.tween_property(pivot, "position:y", 0.0, duration * 0.6)
			active.parallel().tween_property(body, "modulate", profile.tint, duration * 0.6)
		"crisis":
			for angle in [-0.08, 0.08, -0.05, 0.0]:
				active.tween_property(pivot, "rotation:z", angle, duration / 4.0)
		"victory":
			active.tween_property(pivot, "position:y", 0.25, duration * 0.5)
			active.tween_property(pivot, "position:y", 0.0, duration * 0.5)
		"defeat":
			active.tween_property(pivot, "rotation:z", -1.2 * profile.facing, duration)
			active.parallel().tween_property(body, "modulate:a", 0.25, duration)
	active.finished.connect(_next)

func show_state(health: int, maximum: int, shield: int, stress: int = 0) -> void:
	name_label.text = "%s\n%d/%d PV · %d escudo · %d estrés" % [display_name, health, maximum, shield, stress]
	if health <= 0:
		play_animation("defeat")
