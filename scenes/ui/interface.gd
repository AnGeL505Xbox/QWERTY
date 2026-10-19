extends CanvasLayer

signal choose_enemy(index: int)
signal toggle_member(id: String)
signal select_card(index: int)
signal confirm_target(id: String)
signal cancel_selection
signal end_turn
signal retry
signal menu
signal new_expedition(seed_text: String)
signal continue_expedition
signal complete_run_battle
signal settings_requested
signal exit_game

@export var button_scene: PackedScene
@export var card_scene: PackedScene
@export var member_scene: PackedScene
var artwork: Dictionary = {}

func _ready() -> void:
	%SettingsMenu.pressed.connect(func(): settings_requested.emit())
	%SettingsBattle.pressed.connect(func(): settings_requested.emit())
	%NewRun.pressed.connect(func(): new_expedition.emit(%Seed.text))
	%ContinueRun.pressed.connect(func(): continue_expedition.emit())
	%ContinueBattle.pressed.connect(func(): complete_run_battle.emit())
	%Exit.pressed.connect(func(): exit_game.emit())
	%EndTurn.pressed.connect(func(): end_turn.emit())
	%Retry.pressed.connect(func(): retry.emit())
	%MenuButton.pressed.connect(func(): menu.emit())

func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button: Button = button_scene.instantiate()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func show_errors(errors: PackedStringArray) -> void:
	%Menu.visible = false
	%Battle.visible = false
	%Errors.visible = true
	%Errors.text = "Revisa el catálogo en el editor:\n" + "\n".join(errors)

func show_menu(content: Dictionary, team: Array) -> void:
	%Errors.visible = false
	%Menu.visible = true
	%Battle.visible = false
	_clear(%TeamChoices)
	_clear(%EnemyChoices)
	for character in content.characters:
		_button(%TeamChoices, ("✓ " if character.id in team else "+ ") + character.name, func(): toggle_member.emit(character.id))
	for i in range(content.enemies.size()):
		_button(%EnemyChoices, "Combatir: " + content.enemies[i].name, func(): choose_enemy.emit(i))

func show_battle(battle, selected: int) -> void:
	%Menu.visible = false
	%Errors.visible = false
	%Battle.visible = true
	%ContinueBattle.visible = false
	%BattleTitle.text = "Equipo contra %s · Turno %d" % [battle.enemy.name, battle.turn]
	_clear(%Members)
	for member in battle.team:
		var states: Array = []
		for id in member.statuses:
			states.append("%s:%d" % [battle.content.statuses[id].name, member.statuses[id]])
		var condition := "CAÍDO" if not member.alive() else ("CRISIS" if member.crisis else ", ".join(states))
		var row: Label = member_scene.instantiate()
		row.text = "%s · PV %d/%d · Escudo %d · Energía %d · Estrés %d/%d · ATQ %d DEF %d · %s" % [member.definition.name, member.health, member.max_health, member.block, member.energy, member.stress, member.definition.stress_limit, member.stat("attack"), member.stat("defense"), condition]
		%Members.add_child(row)
	var Intent = preload("res://core/enemies/intent.gd")
	%EnemyIntent.text = "Enemigo: %d PV · Escudo %d · Intención: %s" % [battle.enemy_health, battle.enemy_block, Intent.describe(battle.intent) + (" → " + battle.character(battle.intent.target).definition.name if battle.intent.type == "attack" else "")]
	_clear(%Targets)
	_clear(%Cards)
	var ended: bool = not battle.result.is_empty()
	%Result.visible = ended
	%Result.text = battle.result
	%Retry.visible = ended
	%EndTurn.visible = not ended
	%Selection.visible = not ended
	%HandScroll.visible = not ended
	%Targets.visible = not ended and selected >= 0
	if not ended:
		%Selection.text = "Selecciona una carta y confirma el objetivo resaltado (→)."
		if selected >= 0:
			var chosen: Dictionary = battle.card_data(battle.hand[selected])
			%Selection.text = "Seleccionada: %s — %s" % [chosen.name, chosen.description]
			for target in battle.valid_targets(selected):
				var title: String = battle.enemy.name if target == "enemy" else battle.character(chosen.owner if target == "self" else target).definition.name
				_button(%Targets, "→ " + title, func(): confirm_target.emit(target))
			_button(%Targets, "Cancelar", func(): cancel_selection.emit())
		for i in range(battle.hand.size()):
			var card: Dictionary = battle.card_data(battle.hand[i])
			var owner = battle.character(card.owner)
			var view: Button = card_scene.instantiate()
			%Cards.add_child(view)
			view.show_card(card, owner.definition.name, owner.definition.special == card.id, artwork.get(card.id))
			view.disabled = battle.valid_targets(i).is_empty()
			view.pressed.connect(func(): select_card.emit(i))
	%Piles.text = "Mazo: %d · Descarte: %d · Agotadas: %d" % [battle.draw_pile.size(), battle.discard.size(), battle.exhausted.size()]

func hide_all() -> void:
	%Menu.visible = false
	%Battle.visible = false
	%Errors.visible = false

func set_run_status(message: String, can_continue: bool = true) -> void:
	%RunStatus.text = message
	%ContinueRun.disabled = not can_continue

func set_expedition_mode(enabled: bool, ended: bool) -> void:
	%ContinueBattle.visible = enabled and ended
	if enabled:
		%Retry.visible = false

func set_save_notice(message: String) -> void:
	%SaveNotice.text = message
	%SaveNotice.visible = message != ""

func focus_targets() -> void:
	for button in %Targets.get_children():
		if button is Button and not button.disabled:
			button.grab_focus()
			return

func set_adventure_info(text: String) -> void:
	%AdventureInfo.text = text
	%AdventureInfo.visible = text != ""
