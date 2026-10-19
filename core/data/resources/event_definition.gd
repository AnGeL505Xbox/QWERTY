@tool
class_name RpgEventDefinition
extends Resource

@export var id := "nuevo_evento"
@export var display_name := "Nuevo evento"
@export_multiline var description := "Un reflejo cruza el umbral. ¿Qué decides?"
@export var choices: Array[RpgEventChoice] = []

func to_dict() -> Dictionary:
	var options: Array = []
	for choice in choices:
		options.append(choice.to_dict() if choice != null else {})
	return {"id": id, "name": display_name, "description": description, "choices": options}
