extends CanvasLayer

signal applied(values: Dictionary)
signal closed

func _ready() -> void:
	%Apply.pressed.connect(func(): applied.emit({"quality": ["ahorro", "equilibrado", "alto"][%Quality.selected], "fps": 30 if %FPS.selected == 0 else 60, "reduced_motion": %Motion.button_pressed, "effects": %Effects.button_pressed, "fullscreen": %Fullscreen.button_pressed}))
	%Back.pressed.connect(func(): closed.emit())
	%Fullscreen.visible = not OS.has_feature("android")

func open(values: Dictionary, notice: String) -> void:
	%Quality.select(["ahorro", "equilibrado", "alto"].find(values.quality))
	%FPS.select(0 if values.fps == 30 else 1)
	%Motion.button_pressed = values.reduced_motion
	%Effects.button_pressed = values.effects
	%Fullscreen.button_pressed = values.fullscreen
	%Status.text = notice
	visible = true
	%Apply.grab_focus()
