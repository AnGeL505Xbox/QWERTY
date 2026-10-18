extends Node

const Catalog = preload("res://core/data/catalog.gd")
const Battle = preload("res://core/combat/battle.gd")
const Arena = preload("res://visuals/arena.gd")
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
	_button(ui, "Iniciar combate", _start)
	_button(ui, "Salir", func(): get_tree().quit())

func _start() -> void:
	battle = Battle.new(Catalog.load_content(), int(Time.get_ticks_msec()))
	battle.changed.connect(_render)
	battle.action.connect(arena.animate)
	_render()

func _render() -> void:
	_clear()
	_label("Lira contra Eco del vacío", 32)
	_label("Turno %d · Vida %d/%d · Escudo %d · Energía %d" % [battle.turn, battle.health, battle.max_health, battle.block, battle.energy])
	_label("Enemigo: %d PV · Intención: atacar por %d" % [battle.enemy_health, battle.content.enemies[0].damage])
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ui.add_child(spacer)
	if not battle.result.is_empty():
		_label(battle.result, 42)
		_button(ui, "Reintentar", _start)
	else:
		_label("Ataques → enemigo · Escudo y curación → Lira", 18)
		var cards := HBoxContainer.new()
		cards.add_theme_constant_override("separation", 10)
		ui.add_child(cards)
		for i in range(battle.hand.size()):
			var card: Dictionary = battle.card_data(battle.hand[i])
			var button := _button(cards, "%s · %d energía\n%s" % [card.name, card.cost, card.description], _play.bind(i))
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.custom_minimum_size = Vector2(0, 140)
			button.disabled = battle.energy < int(card.cost)
		_button(ui, "Terminar turno", battle.end_turn)
	_label("Mazo: %d · Descarte: %d" % [battle.draw_pile.size(), battle.discard.size()], 18)
	_button(ui, "Menú", _menu)

func _play(index: int) -> void:
	battle.play(index)
