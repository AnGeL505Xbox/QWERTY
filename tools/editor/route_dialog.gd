@tool
extends "res://tools/editor/edit_dialog.gd"

const Editing = preload("res://tools/editor/editing.gd")
const Route = preload("res://core/progression/route.gd")
const TYPES = ["combat", "elite", "event", "reward", "rest", "shop"]
const TITLES = ["Combate", "Élite", "Evento", "Tesoro", "Descanso", "Tienda"]
var catalog: RpgContentCatalog
var rules: RpgRunDefinition
var draft: Array[RpgRouteNode] = []
var draft_rows := 5
var rows: SpinBox
var seed_input: SpinBox
var graph: GraphEdit
var mode_label: Label
var procedural := false

func build() -> void:
	title = "Editor de rutas de expedición"
	note("Conecta la salida derecha de un nodo con la entrada izquierda de la etapa siguiente. Pulsa el puerto conectado para desconectar. Todos los nodos deben ser accesibles y conducir al jefe. Arrastrar una caja solo cambia su posición en esta vista. Regenerar reemplaza el borrador.")
	var toolbar := HBoxContainer.new()
	form.add_child(toolbar)
	rows = spin(toolbar, "Etapas para regenerar", 4, 8)
	seed_input = spin(toolbar, "Semilla de vista previa", 0, 2147483647)
	seed_input.value = 42
	seed_input.value_changed.connect(func(_value):
		if rules != null: _render())
	button(toolbar, "Regenerar borrador", _generate)
	button(toolbar, "Usar ruta procedural", _procedural)
	mode_label = note("")
	graph = GraphEdit.new()
	graph.custom_minimum_size = Vector2(900, 330)
	graph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph.right_disconnects = true
	graph.connection_request.connect(_connect_nodes)
	graph.disconnection_request.connect(_disconnect_nodes)
	form.add_child(graph)

func open_for(content: RpgContentCatalog, run_rules: RpgRunDefinition) -> void:
	catalog = content
	rules = run_rules
	draft_rows = rules.rows
	rows.value = rules.rows
	procedural = rules.route_nodes.is_empty()
	draft = Editing.route_draft(rules, int(seed_input.value))
	_render()
	DialogLayout.open(self)

func _generate() -> void:
	var probe: RpgRunDefinition = rules.duplicate(false)
	probe.route_nodes = []
	probe.rows = int(rows.value)
	draft_rows = probe.rows
	draft = Editing.route_draft(probe, int(seed_input.value))
	procedural = false
	_render()

func _procedural() -> void:
	_generate()
	procedural = true
	_render()

func _preview_config() -> Dictionary:
	var config := rules.to_dict()
	config.rows = draft_rows
	if procedural: config.erase("route_nodes")
	else: config.route_nodes = draft.map(func(node): return node.to_dict() if node != null else {})
	return config

func _render() -> void:
	graph.clear_connections()
	for child in graph.get_children():
		if child is GraphNode:
			graph.remove_child(child)
			child.queue_free()
	var config := _preview_config()
	var nodes: Array = Route.generate(int(seed_input.value), config) if procedural else Route.preview_custom(int(seed_input.value), config)
	if nodes.size() != draft.size():
		report.text = "Hay nodos o reglas incompletas. Corrige el Inspector o regenera el borrador."
		get_ok_button().disabled = true
		return
	mode_label.text = "Procedural: los tipos y enemigos cambian con la semilla. Editar un nodo activa una ruta personalizada." if procedural else "Ruta personalizada: tipos y conexiones fijos; enemigo Automático se elige por semilla."
	for index in range(draft.size()):
		var node := draft[index]
		if node == null: continue
		var box := GraphNode.new()
		box.name = "%d_%d" % [node.row, node.column]
		box.title = "Etapa %d · Carril %d" % [node.row + 1, node.column + 1]
		box.position_offset = Vector2(node.row * 240, node.column * 200 + 20)
		var fields := VBoxContainer.new()
		box.add_child(fields)
		var type_input := OptionButton.new()
		fields.add_child(type_input)
		if node.row == draft_rows - 1:
			type_input.add_item("Jefe final")
			type_input.disabled = true
		else:
			for caption in TITLES: type_input.add_item(caption)
			type_input.select(TYPES.find(nodes[index].type))
			type_input.item_selected.connect(func(selected):
				_materialize_preview()
				node.type = TYPES[selected]
				_render())
		var enemy := OptionButton.new()
		fields.add_child(enemy)
		enemy.add_item("Enemigo automático")
		enemy.set_item_metadata(0, null)
		for encounter in rules.encounters:
			if encounter == null: continue
			enemy.add_item(encounter.display_name)
			enemy.set_item_metadata(enemy.item_count - 1, encounter)
			if encounter == node.enemy: enemy.select(enemy.item_count - 1)
		enemy.disabled = not nodes[index].type in ["combat", "elite"]
		enemy.item_selected.connect(func(selected):
			_materialize_preview()
			node.enemy = enemy.get_item_metadata(selected)
			_render())
		var resolved := Label.new()
		resolved.text = "Semilla: " + nodes[index].enemy if nodes[index].type in ["combat", "elite", "boss"] else "Sin combate"
		fields.add_child(resolved)
		box.set_slot(0, node.row > 0, 0, Color.SKY_BLUE, node.row < draft_rows - 1, 0, Color.PALE_GREEN)
		graph.add_child(box)
	for node in nodes:
		for link in node.links:
			if graph.has_node(NodePath(link)): graph.connect_node(node.id, 0, link, 0)
	_check()

func _materialize_preview() -> void:
	if not procedural: return
	var nodes := Route.generate(int(seed_input.value), _preview_config())
	for index in range(draft.size()):
		draft[index].type = nodes[index].type
		draft[index].links = PackedStringArray(nodes[index].links)
	procedural = false

func _connect_nodes(from: StringName, _from_port: int, to: StringName, _to_port: int) -> void:
	var source := _node(str(from))
	var destination := _node(str(to))
	if source == null or destination == null or destination.row != source.row + 1:
		report.text = "Solo se conectan etapas consecutivas hacia el jefe."
		return
	_materialize_preview()
	if not str(to) in source.links:
		source.links.append(str(to))
		source.links.sort()
	_render()

func _disconnect_nodes(from: StringName, _from_port: int, to: StringName, _to_port: int) -> void:
	_materialize_preview()
	var source := _node(str(from))
	if source == null: return
	var links := Array(source.links)
	links.erase(str(to))
	source.links = PackedStringArray(links)
	_render()

func _node(id: String) -> RpgRouteNode:
	for node in draft:
		if node != null and "%d_%d" % [node.row, node.column] == id: return node
	return null

func _proposal() -> Dictionary:
	var nodes: Array[RpgRouteNode] = []
	if not procedural: nodes = draft
	return Editing.route_proposal(catalog, rules, nodes, draft_rows)

func _check() -> void:
	var proposal := _proposal()
	get_ok_button().disabled = not proposal.errors.is_empty()
	report.text = "Ruta válida. Aplicar cambia las expediciones nuevas; las partidas guardadas conservan su mapa." if proposal.errors.is_empty() else "\n".join(Array(proposal.errors).slice(0, 3))

func submit() -> void:
	publish(_proposal())
