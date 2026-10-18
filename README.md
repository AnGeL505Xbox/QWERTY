# Umbral de Nácar
Prototipo original de RPG de cartas 2.5D, sin conexión. Godot **4.6.3**, GDScript y renderizador Compatibility.

## Ejecutar
Importa `project.godot` en Godot y pulsa F6 sobre `scenes/main.tscn` o F5. Elige un enemigo en el menú. Selecciona una carta y confirma el objetivo señalado con →; también puedes cancelar. Las cartas atacan al enemigo o protegen/curan a Lira. Dispones de 3 de energía por turno; cada enemigo anuncia su próxima acción. Termina el turno para renovar energía y mano. Gana reduciendo su vida a cero. Puedes volver al menú y reiniciar.

Los botones admiten ratón, toque y navegación de foco de Godot. No requieren hover. La verificación táctil en un dispositivo real sigue pendiente.

## Validar
```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/run.gd
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
Fases 1 y 2: una heroína, tres enemigos seleccionables, ocho cartas, mazo con doce entradas, robo, descarte, barajado reproducible, energía, daño, escudo, curación , agotamiento y victoria/derrota. Los enemigos alternan ataques, guardia o curación según patrones editables. Escenario 3D ligero y sprites SVG originales con movimiento de reposo y reacción por color. No es todavía el vertical slice completo.

Consulta `PLAN_DE_DESARROLLO.md`, `ARQUITECTURA.md` y las guías `COMO_*.md`. No se han probado exportaciones, calidad visual en pantalla ni rendimiento Android. No hay guardado todavía.

Pruebas de fase 2: 53 comprobaciones del modelo y recorrido automatizado de selección, confirmación, turno, cambio de enemigo y cancelación. Validación sin interfaz gráfica; revisión visual y dispositivos reales pendiente.
