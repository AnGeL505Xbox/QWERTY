extends SceneTree

func _initialize() -> void:
	var version := Engine.get_version_info()
	var folder := "%d.%d.%d.%s" % [version.major, version.minor, version.patch, version.status]
	var templates := OS.get_data_dir().path_join("godot/export_templates").path_join(folder)
	var android := "--android" in OS.get_cmdline_user_args()
	var requirements: Dictionary = {}
	if android:
		requirements["Plantilla Android debug"] = FileAccess.file_exists(templates.path_join("android_debug.apk"))
		requirements["Plantilla Android release"] = FileAccess.file_exists(templates.path_join("android_release.apk"))
		var sdk := OS.get_environment("ANDROID_HOME")
		if sdk == "": sdk = OS.get_environment("ANDROID_SDK_ROOT")
		requirements["Android SDK declarado y platform-tools instaladas"] = sdk != "" and DirAccess.dir_exists_absolute(sdk.path_join("platform-tools"))
		var java_home := OS.get_environment("JAVA_HOME")
		requirements["JAVA_HOME declarado con JDK"] = java_home != "" and DirAccess.dir_exists_absolute(java_home.path_join("bin"))
	else:
		requirements["Plantilla Windows x86_64 release"] = FileAccess.file_exists(templates.path_join("windows_release_x86_64.exe"))
	var missing := false
	for requirement in requirements:
		print(("OK: " if requirements[requirement] else "FALTA: ") + requirement)
		missing = missing or not requirements[requirement]
	print("Esta comprobación no sustituye la exportación ni las pruebas en el dispositivo.")
	quit(1 if missing else 0)
