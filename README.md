# Umbral de Nácar
Prototipo original de RPG de cartas 2.5D, sin conexión. Godot **4.6.3**, GDScript y renderizador Compatibility.

## Ejecutar
Importa `project.godot` en Godot y pulsa F6 sobre `scenes/main.tscn` o F5. Selecciona de uno a tres integrantes (Lira y Noa disponibles) y elige un enemigo en el menú. Selecciona una carta y confirma el objetivo señalado con →; también puedes cancelar. Cada carta pertenece a un personaje y consume su energía. Las cartas de apoyo permiten elegir un aliado vivo. El daño real acumula estrés; una crisis reduce la energía del siguiente turno. Las habilidades especiales se señalan con ★. Cada enemigo anuncia su próxima acción. Termina el turno para renovar energía y mano. Gana reduciendo su vida a cero. Puedes volver al menú y reiniciar.

Los botones admiten ratón, toque y navegación de foco de Godot. No requieren hover. La verificación táctil en un dispositivo real sigue pendiente.

## Validar
```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/run.gd
godot --headless --path . --script tests/party.gd
godot --headless --path . --script tests/scene_smoke.gd
```
En la máquina de nube, usa directorios escribibles antes de estos comandos:
```sh
export XDG_DATA_HOME=/tmp/qwerty-godot/data
export XDG_CONFIG_HOME=/tmp/qwerty-godot/config
export XDG_CACHE_HOME=/tmp/qwerty-godot/cache
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
```

## Alcance
Fases 1–3: dos personajes originales con estadísticas, pasivas y crisis configurables; tres enemigos seleccionables; catorce cartas y diecinueve entradas entre los mazos de Lira y Noa; robo, descarte, barajado reproducible, energía, daño, escudo, curación, agotamiento y victoria/derrota. Los enemigos alternan ataques, guardia o curación según patrones editables. Escenario 3D ligero y sprites SVG originales con movimiento de reposo y reacción por color. No es todavía el vertical slice completo.

Consulta `PLAN_DE_DESARROLLO.md`, `ARQUITECTURA.md` y las guías `COMO_*.md`. No se han probado exportaciones, calidad visual en pantalla ni rendimiento Android. No hay guardado todavía.

Pruebas de fase 3: 107 comprobaciones de reglas y recorrido de escena con siete verificaciones de selección de equipo, objetivo aliado, cancelación y reinicio. Validación sin interfaz gráfica; revisión visual y dispositivos reales pendiente.

Para probar los estados, juega **Resonancia** o **Pacto protector** de Noa. Usa **Ancla serena** antes de que el estrés alcance el umbral. El menú conserva al menos un integrante y permite volver a jugar con Lira sola. Las reglas detalladas están en `documentation/PERSONAJES_Y_ESTRES.md`.
