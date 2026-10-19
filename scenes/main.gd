extends Node

const Catalog = preload("res://core/data/catalog.gd")
const Expedition = preload("res://core/progression/expedition.gd")
const Store = preload("res://core/save_system/store.gd")
const RunValidator = preload("res://core/save_system/run_validator.gd")
const Battle = preload("res://core/combat/battle.gd")
@export var catalog: RpgContentCatalog
@export var expedition_rules: RpgRunDefinition
@export var save_path := "user://expedition.json"
var run: RefCounted
var save_notice := ""
var team_ids: Array = []
var selected := -1
var enemy_index := 0
var battle: RefCounted
@onready var ui = $Interface
@onready var arena = $Arena
@onready var run_ui = $ExpeditionUI

func _ready() -> void:
	ui.new_expedition.connect(_new_expedition)
	ui.continue_expedition.connect(_continue_expedition)
	ui.complete_run_battle.connect(_complete_run_battle)
	run_ui.selected_node.connect(_enter_node)
	run_ui.selected_choice.connect(_run_choice)
	run_ui.leave.connect(_menu)
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
	if run != null:
		_save_run()
		run = null
	run_ui.visible = false
	selected = -1
	arena.highlight_targets([])
	var errors := Catalog.validate_resource(catalog)
	if not errors.is_empty():
		ui.show_errors(errors)
		return
	ui.show_menu(catalog.to_dict(), team_ids)
	ui.set_run_status(save_notice if save_notice != "" else "Guardado automático. Nueva expedición reemplaza la anterior.", FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path + ".bak"))

func _toggle_member(id: String) -> void:
	if id in team_ids:
		if team_ids.size() > 1:
			team_ids.erase(id)
	elif team_ids.size() < 3:
		team_ids.append(id)
	_menu()

func _choose_enemy(index: int) -> void:
	run = null
	enemy_index = index
	_start()

func _start() -> void:
	if run != null:
		return
	var errors := Catalog.validate_resource(catalog)
	if not errors.is_empty():
		ui.show_errors(errors)
		return
	selected = -1
	battle = Battle.new(catalog.to_dict(), int(Time.get_ticks_msec()), enemy_index, team_ids)
	_bind_battle()

func _bind_battle() -> void:
	run_ui.visible = false
	arena.set_profiles(catalog.visual_profiles())
	if run != null and expedition_rules != null and expedition_rules.boss != null and expedition_rules.boss.visual_profile != null:
		arena.set_profiles({expedition_rules.boss.id: expedition_rules.boss.visual_profile})
	arena.set_team(battle.team)
	arena.set_enemy(battle.enemy)
	ui.artwork = catalog.artwork()
	if not battle.changed.is_connected(_on_battle_changed):
		battle.changed.connect(_on_battle_changed)
	if not battle.combat_event.is_connected(arena.on_combat_event):
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
	ui.set_expedition_mode(run != null, battle.result != "")
	ui.set_save_notice(save_notice if run != null else "")

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

func _on_battle_changed() -> void:
	if run != null and run.battle == battle:
		run.sync_party()
		_save_run()
	_render()

func _new_expedition(seed_text: String) -> void:
	var seed_number := randi_range(0, 2147483647)
	if seed_text != "":
		if not seed_text.is_valid_int() or int(seed_text) < 0 or int(seed_text) > 2147483647:
			ui.set_run_status("Usa una semilla entera entre 0 y 2147483647.")
			return
		seed_number = int(seed_text)
	var errors := Catalog.validate_resource(catalog)
	if expedition_rules == null:
		errors.append("Falta el recurso de configuración de expedición.")
	elif errors.is_empty():
		errors.append_array(RunValidator.resource_configuration(catalog, expedition_rules))
	if not errors.is_empty():
		ui.set_run_status("; ".join(errors))
		return
	run = Expedition.new(catalog.to_dict(), expedition_rules.to_dict(), seed_number, team_ids)
	_save_run()
	_show_run()

func _continue_expedition() -> void:
	var loaded := Store.read(save_path)
	if not loaded.has("state"):
		ui.set_run_status(loaded.error)
		return
	run = Expedition.restore(loaded.state)
	save_notice = loaded.get("warning", "")
	_show_run()

func _show_run() -> void:
	selected = -1
	arena.highlight_targets([])
	if run.phase == "combat":
		battle = run.battle
		_bind_battle()
	else:
		ui.hide_all()
		run_ui.display(run, save_notice)

func _enter_node(id: String) -> void:
	if run != null and run.enter(id):
		run.sync_party()
		_save_run()
		_show_run()

func _run_choice(action: String, id: String) -> void:
	if run != null and run.choose(action, id):
		_save_run()
		_show_run()

func _complete_run_battle() -> void:
	if run != null and run.finish_battle():
		_save_run()
		_show_run()

func _save_run() -> void:
	if run != null:
		save_notice = Store.write(save_path, run.export_state())
