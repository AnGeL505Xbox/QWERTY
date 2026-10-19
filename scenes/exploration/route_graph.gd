@tool
extends Control

signal selected(id: String)
@export var preview_rules: RpgRunDefinition
@export var preview_seed := 42
var preview_hash := 0
@export var node_scene: PackedScene
@export var step := Vector2(215, 110)
@export var origin := Vector2(20, 20)
@export var connection_color := Color(0.35, 0.55, 0.65)
var nodes: Array = []
var positions: Dictionary = {}

func _ready() -> void:
	set_process(Engine.is_editor_hint())

func _process(_delta: float) -> void:
	if preview_rules != null:
		var rules := preview_rules.to_dict()
		var fingerprint := hash([rules, preview_seed, step, origin])
		if fingerprint != preview_hash and not rules.encounters.is_empty() and rules.boss.has("id"):
			preview_hash = fingerprint
			var preview: Array = preload("res://core/progression/route.gd").generate(preview_seed, rules)
			_build(preview, preview.filter(func(node): return node.row == 0).map(func(node): return node.id), [], int(rules.rows), rules.get("biomes", []))

func display(run) -> void:
	_build(run.nodes, run.available(), run.visited, int(run.config.rows), run.config.get("biomes", []))

func _build(route_nodes: Array, available: Array, visited: Array, rows: int, biomes: Array = []) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	nodes = route_nodes
	positions.clear()
	custom_minimum_size = Vector2(origin.x * 2 + step.x * rows, origin.y * 2 + step.y * 2)
	for node in nodes:
		var view: Button = node_scene.instantiate()
		view.position = origin + Vector2(node.row * step.x, node.column * step.y)
		view.text = ("✓ " if node.id in visited else "") + title(node.type) + "\n" + node.id
		for biome in biomes:
			if biome.id == node.get("biome", ""):
				view.text = ("✓ " if node.id in visited else "") + title(node.type) + "\n" + str(biome.name) + "\n" + node.id
				view.modulate = Color(str(biome.color)).lightened(0.4)
		view.disabled = not node.id in available
		view.pressed.connect(func(): selected.emit(node.id))
		add_child(view)
		positions[node.id] = view.position + view.custom_minimum_size * 0.5
	queue_redraw()

func _draw() -> void:
	for node in nodes:
		for target in node.links:
			if positions.has(target):
				draw_line(positions[node.id], positions[target], connection_color, 3.0, true)

static func title(kind: String) -> String:
	return {"combat": "Combate", "elite": "Élite", "boss": "Jefe", "rest": "Descanso", "shop": "Tienda", "event": "Evento", "reward": "Tesoro"}.get(kind, kind)
