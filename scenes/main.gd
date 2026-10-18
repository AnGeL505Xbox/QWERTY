extends Node

const Catalog = preload("res://core/data/catalog.gd")
const Battle = preload("res://core/combat/battle.gd")
const Arena = preload("res://visuals/arena.gd")
const Intent = preload("res://core/enemies/intent.gd")
var selected := -1
var enemy_index := 0
var battle: RefCounted
var ui: VBoxContainer
var arena: Node3D

func _ready() -> void:
	arena = Arena.new()
	add_child(arena)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	canvas.add_child(margin)
	ui = VBoxContainer.new()
	ui.add_theme_constant_override("separation", 12)
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
	ui.add_child(label)

func _button(parent: Node, title: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(180, 64)
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _menu() -> void:
	_clear()
	_label("UMBRAL DE NÁCAR", 44)
	_label("Expedición 01 · El eco del vacío")
	_label("Prototipo: cartas, energía y combate por turnos", 20)
	var content := Catalog.load_content()
	for i in range(content.enemies.size()):
		_button(ui, "Combatir: " + content.enemies[i].name, _choose_enemy.bind(i))
	_button(ui, "Salir", func(): get_tree().quit())

func _choose_enemy(index: int) -> void:
	enemy_index = index
	_start()

func _start() -> void:
	selected = -1
	battle = Battle.new(Catalog.load_content(), int(Time.get_ticks_msec()), enemy_index)
	battle.changed.connect(_render)
	battle.action.connect(arena.animate)
	_render()

func _render() -> void:
	_clear()
	_label("%s contra %s" % [battle.content.characters[0].name, battle.enemy.name], 32)
	_label("Turno %d · Vida %d/%d · Escudo %d · Energía %d" % [battle.turn, battle.health, battle.max_health, battle.block, battle.energy])
	_label("Enemigo: %d PV · Escudo %d · Intención: %s" % [battle.enemy_health, battle.enemy_block, Intent.describe(battle.intent)], 20)
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
				_button(targets, "→ " + (battle.enemy.name if target == "enemy" else battle.content.characters[0].name), _confirm.bind(target))
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
			var button := _button(cards, "%s · %d energía\n%s" % [card.name, card.cost, card.description], _select.bind(i))
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.custom_minimum_size = Vector2(210, 140)
			button.disabled = battle.energy < int(card.cost)
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
