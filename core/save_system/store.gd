extends RefCounted

const Validator = preload("res://core/save_system/run_validator.gd")
const VERSION = 1
const MAX_BYTES = 4 * 1024 * 1024

static func write(path: String, state: Dictionary) -> String:
	var errors := Validator.validate(state)
	if not errors.is_empty():
		return "No se guardó: " + "; ".join(errors)
	var payload := JSON.stringify(state)
	var envelope := JSON.stringify({"version": VERSION, "payload": payload, "checksum": payload.sha256_text()})
	if envelope.to_utf8_buffer().size() > MAX_BYTES:
		return "La partida supera el tamaño máximo de guardado."
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return "No se pudo abrir el archivo temporal de guardado."
	file.store_string(envelope)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return "No se pudo escribir el guardado."
	var destination := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		var previous := _read_one(path)
		var backup := destination + (".bak" if previous.has("state") else ".corrupt_" + str(Time.get_ticks_usec()))
		if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup) != OK:
			return "No se pudo renovar la copia de seguridad."
		if DirAccess.rename_absolute(destination, backup) != OK:
			return "No se pudo conservar el guardado anterior."
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), destination) != OK:
		return "No se pudo finalizar el guardado. La copia anterior permanece en .bak."
	return ""

static func read(path: String) -> Dictionary:
	var result := _read_one(path)
	if result.has("state"):
		return result
	var backup := _read_one(path + ".bak")
	if backup.has("state"):
		backup["warning"] = "Se recuperó la copia anterior porque el guardado principal no era válido."
		return backup
	return result

static func _read_one(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"error": "No hay una expedición guardada."}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES:
		return {"error": "Archivo de guardado inaccesible o demasiado grande."}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {"error": "El archivo de guardado está incompleto o no es JSON válido."}
	var envelope = parser.data
	if not envelope is Dictionary or envelope.get("version") != VERSION:
		return {"error": "Guardado inválido o de una versión no compatible. Se conserva el archivo."}
	# La versión 1 es el primer formato. Las migraciones futuras se añaden aquí antes de validar.
	if not envelope.get("payload") is String or not envelope.get("checksum") is String or envelope.payload.sha256_text() != envelope.checksum:
		return {"error": "El guardado está incompleto o tiene un checksum incorrecto."}
	var payload_parser := JSON.new()
	if payload_parser.parse(envelope.payload) != OK:
		return {"error": "El contenido de la expedición no es JSON válido."}
	var state = payload_parser.data
	if not state is Dictionary:
		return {"error": "El guardado no contiene una expedición."}
	var errors := Validator.validate(state)
	if not errors.is_empty():
		return {"error": "Guardado incompatible: " + "; ".join(errors)}
	return {"state": state}
