extends Node

const Catalog = preload("res://core/data/catalog.gd")
const Battle = preload("res://core/combat/battle.gd")
@export var catalog: RpgContentCatalog
var team_ids: Array = []
var selected := -1
var enemy_index := 0
var battle: RefCounted
@onready var ui = $Interface
@onready var arena = $Arena

func _ready() -> void:
	ui.choose_enemy.connect(_choose_enemy)
	ui.toggle_member.connect(_toggle_member)
	ui.select_card.connect(_select)
	ui.confirm_target.connect(_confirm)
	ui.cancel_selection.connect(_cancel)
	ui.end_turn.connect(_end_turn)
	ui.retry.connect(_start)
	ui.menu.connect(_menu)
	ui.exit_game.connect(func(): get_tree().quit())
	var errors := Catalog.validate_resource(catalog)
	if not errors.is_empty():
		ui.show_errors(errors)
		return
	team_ids = catalog.to_dict().team.duplicate()
	_menu()

func _menu() -> void:
	selected = -1
	arena.highlight_targets([])
	var errors := Catalog.validate_resource(catalog)
	if not errors.is_empty():
		ui.show_errors(errors)
		return
	ui.show_menu(catalog.to_dict(), team_ids)

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
	var errors := Catalog.validate_resource(catalog)
	if not errors.is_empty():
		ui.show_errors(errors)
		return
	selected = -1
	battle = Battle.new(catalog.to_dict(), int(Time.get_ticks_msec()), enemy_index, team_ids)
	arena.set_profiles(catalog.visual_profiles())
	arena.set_team(battle.team)
	arena.set_enemy(battle.enemy)
	ui.artwork = catalog.artwork()
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
	ui.show_battle(battle, selected)

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
