extends CanvasLayer

signal selected_node(id: String)
signal selected_choice(action: String, id: String)
signal leave
@export var button_scene: PackedScene

func _ready() -> void:
	%Route.selected.connect(func(id): selected_node.emit(id))
	%Return.pressed.connect(func(): leave.emit())

func display(run, notice: String = "") -> void:
	visible = true
	%Title.text = "Expedición · Semilla %s · Oro %d" % [run.seed_value, run.gold]
	var summaries: Array[String] = []
	for id in run.team_ids:
		var state: Dictionary = run.party[id]
		summaries.append("%s: %d PV · %d estrés" % [id.capitalize(), state.health, state.stress])
	%Party.text = " / ".join(summaries)
	%Inventory.text = "Mazo: %d cartas · Mejoras: %s" % [_deck_size(run), str(run.upgrades)]
	%Notice.text = notice
	%MapScroll.visible = run.phase == "map"
	if run.phase == "map":
		%Route.display(run)
	for child in %Choices.get_children():
		%Choices.remove_child(child)
		child.queue_free()
	%Message.text = {"map": "Elige un nodo conectado resaltado. Las rutas convergen en el jefe.", "reward": "Elige una recompensa. El oro del encuentro ya se añadió.", "rest": "Descanso: cura a los integrantes vivos y reduce estrés, o mejora una carta.", "shop": "Compra cartas o mejoras con oro. Puedes salir sin comprar.", "event": "Una fuente de nácar: acepta su riesgo por oro o recupérate sin coste.", "victory": "¡Expedición completada! Has vencido al Guardián del umbral.", "defeat": "La expedición ha terminado. Puedes iniciar otra desde el menú."}.get(run.phase, "")
	if run.phase == "reward":
		for offer in run.offers:
			_choice(_offer_title(run, offer), offer.action, offer.id)
	elif run.phase == "rest":
		_choice("Curar +%d PV y aliviar %d estrés" % [run.config.rest_heal, run.config.stress_relief], "heal")
		for id in run.upgradeable():
			_choice("Mejorar " + run.card(id).name, "upgrade", id)
	elif run.phase == "shop":
		for offer in run.offers:
			_choice(_offer_title(run, offer) + " · %d oro" % run.config.card_price, "card", offer.id, run.gold >= int(run.config.card_price))
		for id in run.upgradeable():
			_choice("Mejorar %s · %d oro" % [run.card(id).name, run.config.upgrade_price], "upgrade", id, run.gold >= int(run.config.upgrade_price))
		_choice("Salir de la tienda", "leave")
	elif run.phase == "event":
		_choice("Aceptar: +%d oro, -%d PV por integrante vivo" % [run.config.event_gold, run.config.event_damage], "risk")
		_choice("Recuperar +%d PV y aliviar estrés" % run.config.rest_heal, "heal")

func _choice(text: String, action: String, id: String = "", enabled: bool = true) -> void:
	var button: Button = button_scene.instantiate()
	button.text = text
	button.disabled = not enabled
	button.pressed.connect(func(): selected_choice.emit(action, id))
	%Choices.add_child(button)

func _offer_title(run, offer: Dictionary) -> String:
	if offer.action == "skip":
		return "Conservar el mazo sin cambios"
	return ("Añadir copia: " if offer.action == "card" else "Mejorar: ") + str(run.card(offer.id).name)

func _deck_size(run) -> int:
	var count := 0
	for character in run.content.characters:
		if character.id in run.team_ids:
			count += character.deck.size()
	return count
