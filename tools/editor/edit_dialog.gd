@tool
extends ConfirmationDialog

const DialogLayout = preload("res://tools/editor/dialog_layout.gd")

signal proposal_ready(proposal: Dictionary)
var form: VBoxContainer
var report: Label

func _ready() -> void:
	dialog_hide_on_ok = false
	get_ok_button().text = "Aplicar borrador"
	form = VBoxContainer.new()
	form.custom_minimum_size = Vector2(820, 540)
	DialogLayout.wrap(self, form)
	build()
	report = Label.new()
	report.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	form.add_child(report)
	confirmed.connect(submit)

func build() -> void: pass
func submit() -> void: pass

func publish(proposal: Dictionary) -> void:
	if not proposal.errors.is_empty():
		report.text = "\n".join(proposal.errors)
		return
	proposal_ready.emit(proposal)
	hide()

func note(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	form.add_child(label)
	return label

func button(parent: Node, text: String, callback: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.pressed.connect(callback)
	parent.add_child(result)
	return result

func line(parent: Node, label: String) -> LineEdit:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	var caption := Label.new()
	caption.text = label
	box.add_child(caption)
	var input := LineEdit.new()
	box.add_child(input)
	return input

func spin(parent: Node, label: String, minimum: int, maximum: int) -> SpinBox:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	var caption := Label.new()
	caption.text = label
	box.add_child(caption)
	var input := SpinBox.new()
	input.min_value = minimum
	input.max_value = maximum
	box.add_child(input)
	return input
