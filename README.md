# Umbral de Nácar
Prototipo original de RPG de cartas 2.5D, sin conexión. Godot **4.6.3**, GDScript y renderizador Compatibility.

## Ejecutar
Importa `project.godot` en Godot y pulsa F6 sobre `scenes/main.tscn` o F5. Selecciona de uno a tres integrantes (Lira y Noa disponibles) y elige un enemigo en el menú. Selecciona una carta y confirma el objetivo señalado con →; también puedes cancelar. Cada carta pertenece a un personaje y consume su energía. Las cartas de apoyo permiten elegir un aliado vivo. El daño real acumula estrés; una crisis reduce la energía del siguiente turno. Las habilidades especiales se señalan con ★. Cada enemigo anuncia su próxima acción. Termina el turno para renovar energía y mano. Gana reduciendo su vida a cero. Puedes volver al menú y reiniciar.

Los botones admiten ratón, toque y navegación de foco de Godot. No requieren hover. La verificación táctil en un dispositivo real sigue pendiente.

## Expedición roguelike
En el menú elige equipo y semilla (por ejemplo **42**) y pulsa **Nueva expedición**. Recorre cinco etapas conectadas hasta el jefe; gana oro, cartas y mejoras, visita tienda o descanso y decide en eventos. Vida y estrés se conservan entre combates. **Continuar expedición** recupera incluso un combate interrumpido; el guardado es local en `user://expedition.json` y hay un solo espacio.

Los combates de entrenamiento siguen disponibles. Consulta [ROGUELIKE_Y_GUARDADO.md](documentation/ROGUELIKE_Y_GUARDADO.md) para reglas, edición visual y recuperación.

## Edición visual
Abre el panel **Contenido** en Godot para acceder al catálogo, escenas y validación. Las cartas, personajes, enemigos y estados son Resources `.tres` editables en el Inspector. Escenario, cámara, posiciones, menú, HUD y plantillas están en escenas `.tscn`.

Empieza por [EDICION_VISUAL.md](EDICION_VISUAL.md). Por ejemplo, abre `data/cards/corte.tres`, modifica **Effects → 0 → Amount**, guarda y pulsa F5. **La fuente activa es `data/catalog.tres`**; el JSON anterior se conserva como referencia histórica y ya no se lee al ejecutar.

## Validar
```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/run.gd
godot --headless --path . --script tests/party.gd
godot --headless --path . --script tests/presentation.gd
godot --headless --path . --script tests/scene_smoke.gd
godot --headless --path . --script tests/visual_editing.gd
godot --headless --path . --script tests/roguelike.gd
godot --headless --path . --script tests/roguelike_scene.gd
godot --headless --path . --script tests/authoring.gd
godot --headless --path . --script tests/editor_workflows.gd
godot --headless --path . --script tests/platform_ui.gd
godot --headless --editor --path . -- --test-content-editors
```
En la máquina de nube, usa directorios escribibles antes de estos comandos:
```sh
export XDG_DATA_HOME=/tmp/qwerty-godot/data
export XDG_CONFIG_HOME=/tmp/qwerty-godot/config
export XDG_CACHE_HOME=/tmp/qwerty-godot/cache
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
```

## Alcance
Fases 1–5 y edición visual: dos personajes originales con estadísticas, pasivas y crisis configurables; tres enemigos seleccionables; catorce cartas y diecinueve entradas entre los mazos de Lira y Noa; robo, descarte, barajado reproducible, energía, daño, escudo, curación, agotamiento y victoria/derrota. Los enemigos alternan ataques, guardia o curación según patrones editables. Escenario 3D ligero con profundidad y paralaje, perfiles visuales editables, sprites SVG originales, nueve animaciones de respaldo y efectos de combate. No es todavía el vertical slice completo.

Consulta `PLAN_DE_DESARROLLO.md`, `ARQUITECTURA.md` y las guías `COMO_*.md`. Se generaron exportaciones Windows y Android; su ejecución nativa, la revisión gráfica y el rendimiento en dispositivos siguen pendientes. Hay guardado de expedición; no hay metaprogresión todavía.

Validación actual: 458 comprobaciones sin fallos (53 de combate, 54 de personajes, 39 de presentación, 7 de escena, 37 de edición visual, 64 de roguelike, 26 de su interfaz, 52 de herramientas, 67 de editores y 19 de integración con el editor nativo y 40 de plataforma/UI). Incluyen expediciones completas con cartas/turnos reales, carga intermedia y recuperación de copia. Validación sin interfaz gráfica; revisión visual y dispositivos reales pendiente.

Para probar los estados, juega **Resonancia** o **Pacto protector** de Noa. Usa **Ancla serena** antes de que el estrés alcance el umbral. El menú conserva al menos un integrante y permite volver a jugar con Lira sola. Las reglas detalladas están en `documentation/PERSONAJES_Y_ESTRES.md`.

Fase 4: los objetivos se resaltan en el escenario y los efectos muestran cambios reales. Puedes sustituir imágenes, SpriteFrames y nombres de clips desde perfiles `.tres`: consulta `COMO_CAMBIAR_GRAFICOS.md` y `documentation/PRESENTACION_2_5D.md`.

La configuración roguelike se edita en `data/progression/expedition.tres`; las nuevas pantallas están en `scenes/exploration/`. El catálogo original no se modifica al obtener cartas o mejoras durante una partida.

Fase 7 implementada antes de 6 y 8: consulta [HERRAMIENTAS_DE_CONTENIDO.md](HERRAMIENTAS_DE_CONTENIDO.md) para crear y duplicar contenido desde el panel, configurar recompensas y editar eventos.

Puedes editar mazos, decisiones de eventos y rutas desde el panel **Contenido**: [guía de los tres editores](EDITORES_DE_MAZOS_EVENTOS_Y_RUTAS.md). Aplicar admite Deshacer/Rehacer; después usa Guardar contenido. Las rutas siguen admitiendo generación procedural.

Fase 6: [UI, controles y ajustes](FASE_6_MULTIPLATAFORMA.md); [preparación y exportación](EXPORTAR_PC_ANDROID.md). Pulsa **Ajustes** o F10; 1–9 seleccionan cartas y E termina turno. Las ventanas de herramientas ahora se acotan al área disponible y permiten desplazarse. Cada paquete de recursos Windows/Android pasó además siete comprobaciones en Linux; esto no prueba sus binarios nativos.
