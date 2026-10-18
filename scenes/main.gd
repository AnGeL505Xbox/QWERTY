extends Node

const Catalog = preload("res://core/data/catalog.gd")
const Battle = preload("res://core/combat/battle.gd")
const Arena = preload("res://visuals/arena.gd")
const Intent = preload("res://core/enemies/intent.gd")
var team_ids: Array = []
var selected := -1
var enemy_index := 0
var battle: RefCounted
var ui: VBoxContainer
var arena: Node3D

func _ready() -> void:
	team_ids = Catalog.load_content().team.duplicate()
	arena = Arena.new()
	add_child(arena)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	canvas.add_child(margin)
	ui = VBoxContainer.new()
	ui.add_theme_constant_override("separation", 8)
	margin.add_child(ui)
	_menu()

func _clear() -> void:
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()

func _label(value: String, size: int = 24) -> void:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Color("10182f"))
	label.add_theme_constant_override("outline_size", 4)
	ui.add_child(label)

func _button(parent: Node, title: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(180, 48)
	button.add_theme_font_size_override("font_size", 20)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("19263d")
	style.border_color = Color("548698")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	button.add_theme_stylebox_override("normal", style)
	var highlighted := style.duplicate()
	highlighted.bg_color = Color("30485e")
	highlighted.border_color = Color("e5d9a8")
	button.add_theme_stylebox_override("hover", highlighted)
	button.add_theme_stylebox_override("focus", highlighted)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _menu() -> void:
	selected = -1
	arena.highlight_targets([])
	_clear()
	_label("UMBRAL DE NÁCAR", 44)
	_label("Expedición 01 · El eco del vacío")
	_label("Prototipo: cartas, energía y combate por turnos", 20)
	var content := Catalog.load_content()
	_label("Equipo (1–3): pulsa para incluir o retirar", 18)
	var choices := HBoxContainer.new()
	ui.add_child(choices)
	for character in content.characters:
		_button(choices, ("✓ " if character.id in team_ids else "+ ") + character.name, _toggle_member.bind(character.id))
	for i in range(content.enemies.size()):
		_button(ui, "Combatir: " + content.enemies[i].name, _choose_enemy.bind(i))
	_button(ui, "Salir", func(): get_tree().quit())

func _toggle_member(id: String) -> void:
	if id in team_ids:
		if team_ids.size() > 1:
			team_ids.erase(id)
	elif team_ids.size() < 3:
		team_ids.append(id)
	_menu()

func _choose_enemy(index: int) -> void:
	enemy_index = index
	_start()

func _start() -> void:
	selected = -1
	battle = Battle.new(Catalog.load_content(), int(Time.get_ticks_msec()), enemy_index, team_ids)
	arena.set_team(battle.team)
	arena.set_enemy(battle.enemy)
	battle.changed.connect(_render)
	battle.combat_event.connect(arena.on_combat_event)
	_render()

func _render() -> void:
	arena.sync_battle(battle)
	var highlighted: Array = []
	if selected >= 0:
		var card: Dictionary = battle.card_data(battle.hand[selected])
		for id in battle.valid_targets(selected):
			highlighted.append(card.owner if id == "self" else id)
	arena.highlight_targets(highlighted)
	_clear()
	_label("Equipo contra %s · Turno %d" % [battle.enemy.name, battle.turn], 24)
	for member in battle.team:
		var states: Array = []
		for id in member.statuses:
			states.append("%s:%d" % [battle.content.statuses[id].name, member.statuses[id]])
		var condition := "CAÍDO" if not member.alive() else ("CRISIS" if member.crisis else ", ".join(states))
		_label("%s · PV %d/%d · Escudo %d · Energía %d · Estrés %d/%d · ATQ %d DEF %d · %s" % [member.definition.name, member.health, member.max_health, member.block, member.energy, member.stress, member.definition.stress_limit, member.stat("attack"), member.stat("defense"), condition], 16)
	_label("Enemigo: %d PV · Escudo %d · Intención: %s" % [battle.enemy_health, battle.enemy_block, Intent.describe(battle.intent) + (" → " + battle.character(battle.intent.target).definition.name if battle.intent.type == "attack" else "")], 18)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ui.add_child(spacer)
	if not battle.result.is_empty():
		_label(battle.result, 42)
		_button(ui, "Reintentar", _start)
	else:
		if selected >= 0:
			var chosen: Dictionary = battle.card_data(battle.hand[selected])
			_label("Seleccionada: %s — %s" % [chosen.name, chosen.description], 18)
			var targets := HBoxContainer.new()
			ui.add_child(targets)
			for target in battle.valid_targets(selected):
				_button(targets, "→ " + (battle.enemy.name if target == "enemy" else battle.character(chosen.owner if target == "self" else target).definition.name), _confirm.bind(target))
			_button(targets, "Cancelar", _cancel)
		else:
			_label("Selecciona una carta y confirma el objetivo resaltado (→).", 18)
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size.y = 155
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		ui.add_child(scroll)
		var cards := HBoxContainer.new()
		cards.add_theme_constant_override("separation", 10)
		scroll.add_child(cards)
		for i in range(battle.hand.size()):
			var card: Dictionary = battle.card_data(battle.hand[i])
			var button := _button(cards, "%s · %s · %d E\n%s" % [("★ " if battle.character(card.owner).definition.special == card.id else "") + card.name, battle.character(card.owner).definition.name, card.cost, card.description], _select.bind(i))
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.custom_minimum_size = Vector2(210, 140)
			button.disabled = battle.valid_targets(i).is_empty()
		_button(ui, "Terminar turno", _end_turn)
	_label("Mazo: %d · Descarte: %d · Agotadas: %d" % [battle.draw_pile.size(), battle.discard.size(), battle.exhausted.size()], 18)
	_button(ui, "Menú", _menu)

func _select(index: int) -> void:
	selected = index
	_render()

func _cancel() -> void:
	selected = -1
	_render()

func _confirm(target: String) -> void:
	var index := selected
	selected = -1
	battle.play(index, target)

func _end_turn() -> void:
	selected = -1
	battle.end_turn()
