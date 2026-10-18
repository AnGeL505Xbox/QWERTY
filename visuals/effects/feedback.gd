extends Node3D

const MAX_EFFECTS = 24
@export var enabled := true
var count := 0

func show_at(at: Vector3, text: String, color: Color) -> void:
	if not enabled or get_child_count() >= MAX_EFFECTS - 1:
		return
	count += 1
	var label := Label3D.new()
	label.text = text
	label.font_size = 44
	label.pixel_size = 0.008
	label.modulate = color
	label.position = at + Vector3(0, 1.0, 0.1)
	label.no_depth_test = true
	add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y + 0.7, 0.65)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.65)
	tween.tween_callback(label.queue_free)
	var pulse := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.3
	ring.outer_radius = 0.36
	ring.rings = 16
	ring.ring_segments = 8
	pulse.mesh = ring
	pulse.position = at + Vector3(0, -1.05, 0)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	pulse.material_override = material
	add_child(pulse)
	var pulse_tween := pulse.create_tween()
	pulse_tween.tween_property(pulse, "scale", Vector3(2.1, 1, 2.1), 0.4)
	pulse_tween.parallel().tween_property(material, "albedo_color:a", 0.0, 0.4)
	pulse_tween.tween_callback(pulse.queue_free)

func clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
