@tool
extends Button

var preview_hash := 0

@export var preview_card: RpgCardDefinition:
	set(value):
		preview_card = value
		if is_node_ready() and Engine.is_editor_hint():
			_preview()

func _ready() -> void:
	set_process(Engine.is_editor_hint())
	if Engine.is_editor_hint():
		_preview()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and preview_card != null:
		var value := hash([preview_card.to_dict(), preview_card.illustration])
		if value != preview_hash:
			_preview()

func _preview() -> void:
	if preview_card != null:
		preview_hash = hash([preview_card.to_dict(), preview_card.illustration])
		show_card(preview_card.to_dict(), preview_card.owner, false, preview_card.illustration)

func show_card(card: Dictionary, owner_name: String, special: bool, artwork: Texture2D = null) -> void:
	%Name.text = ("★ " if special else "") + str(card.name)
	%Cost.text = "%s · %d energía" % [owner_name, card.cost]
	%Description.text = card.description
	%Artwork.texture = artwork
	%Artwork.visible = artwork != null
