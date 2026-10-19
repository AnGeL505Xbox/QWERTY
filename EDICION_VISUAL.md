# Editar visualmente en Godot
Usa **Godot 4.6.3**. Abre `project.godot` y espera a que termine la importación. Trabaja en una rama y guarda los archivos antes de pulsar **F5**.

## Primer recorrido: cambiar daño sin programar
1. En el panel **Contenido**, selecciona `cards · Corte de nácar`. También puedes abrir `data/cards/corte.tres` desde Sistema de archivos.
2. En el Inspector cambia **Cost** para su energía. Despliega **Effects → 0** y modifica **Amount** para el daño.
3. Actualiza **Description** para que coincida con las reglas; este texto no se calcula automáticamente.
4. Guarda el recurso, pulsa **Validar contenido** y ejecuta **F5**. La carta sigue perteneciendo a Lira y utiliza los valores nuevos.

El panel Contenido se incluye como complemento local. Si no aparece, actívalo en **Proyecto → Ajustes del proyecto → Complementos → Contenido de Umbral**. No requiere instalación externa. **Actualizar lista** recoge cartas o personajes que hayas añadido a los arrays del catálogo. La validación usa el catálogo seleccionado en el Inspector, o el último catálogo abierto desde el panel (por defecto `data/catalog.tres`).

## Qué abrir para cada tarea
| Quiero modificar | Archivo o nodo |
| --- | --- |
| Coste, descripción, efectos e ilustración de una carta | `data/cards/*.tres` |
| Vida, ataque, defensa, energía, estrés, pasivas y mazo | `data/characters/*.tres` |
| Vida y patrón de un enemigo | `data/enemies/*.tres` |
| Nombre y magnitud de un estado | `data/statuses/*.tres` |
| Reglas roguelike, encuentros, precios y mejoras | `data/progression/expedition.tres` |
| Mapa, recompensas y plantilla de nodos | `scenes/exploration/run_ui.tscn`, `node_button.tscn` |
| Catálogo, equipo inicial y tamaño de mano | `data/catalog.tres` |
| Suelo, columnas, cristales, materiales y luz | `scenes/visuals/arena.tscn` → `Stage`, `Sun`, `WorldEnvironment` |
| Cámara y paralaje | `arena.tscn` → `Camera3D`; raíz Arena → Motion Enabled / Motion Amplitude |
| Posiciones de los combatientes | `arena.tscn` → `AllySlots/Slot1…3` y `EnemySlot` |
| Imagen y SpriteFrames de cada combatiente | Campo **Visual Profile** de su definición → recurso `.tres` |
| Forma, escala u offsets del personaje | `scenes/visuals/actor.tscn` → `Pivot/VisualOffset` |
| Posición de nombre o anillo de objetivo | `actor.tscn` → `NameLabel`, `TargetMarker` |
| Menú, HUD, márgenes, acciones y disposición | `scenes/ui/interface.tscn` |
| Colores, bordes, fuentes y estilos compartidos | `scenes/ui/theme.tres` |
| Diseño de todas las cartas | `scenes/ui/card.tscn` |
| Botones de selección creados durante la partida | `scenes/ui/action_button.tscn` |
| Fila de estadísticas de un personaje | `scenes/ui/member_row.tscn` |

## Escenario y personajes en 3D
Abre `arena.tscn` desde el botón **Escenario 3D**. Ahora hay nodos reales que puedes seleccionar, mover, escalar y duplicar. La cámara, el suelo y los materiales no se reconstruyen mediante código al ejecutar.

Los tres marcadores de aliados contienen instancias del personaje visual. Se reutilizan y se reinician entre combates; no se crean nuevas posiciones por código. Puedes editar el transform de los marcadores para recolocar a los personajes. El slot que no tenga un integrante se oculta al iniciar combate. Para modificar hijos de una instancia usa **Hijos editables / Editable Children**, o abre su escena original. La escena original modifica todas las instancias; una modificación local solo afecta ese slot.

`Pivot` está reservado al movimiento de animación y se reinicia durante las acciones. Utiliza `VisualOffset` para ajustes permanentes de posición, rotación o escala. Textura, tinte, tamaño por píxel y SpriteFrames se toman del **Visual Profile** del personaje/enemigo cuando comienza un combate. Edita ese perfil para que los cambios de imagen sean permanentes. `actor.tscn` ofrece vista previa de su Profile en el editor.

## Interfaz en 2D
Abre `interface.tscn` desde **Interfaz 2D**. El HUD está visible como referencia al editar; alterna la visibilidad de `Menu` y `Battle` en el árbol para trabajar en cada pantalla. Al ejecutar, la pantalla activa la decide el controlador.

Los Containers ordenan sus hijos automáticamente. Ajusta márgenes, separación, tamaños mínimos, Size Flags y anchors para cambiar la disposición. Si necesitas distribución libre, reorganiza los nodos dentro de la misma escena conservando sus nombres únicos (`%...`). No borres los nodos funcionales.

El texto del título del menú y los botones fijos se conserva. Los textos de vida, intención, resultado y descripción se actualizan con datos reales durante la partida. Las cartas, filas y botones repetidos se instancian desde sus **PackedScene**; no se dibujan de nuevo con estilos escritos en código. Edita las plantillas, no añadas ejemplos al contenedor `Cards`, `Members`, `TeamChoices` o `EnemyChoices`: esos contenedores se rellenan y vacían durante el juego.

En `card.tscn`, selecciona la raíz y cambia **Preview Card** para previsualizar una definición. Los campos del recurso se reflejan en esa vista previa. La imagen se asigna en **Illustration** de la carta. Para ilustraciones mayores, amplía el alto de la plantilla y de `HandScroll` en la interfaz; comprueba que quepa en la pantalla.

## Crear contenido nuevo
Usa clic derecho → **Duplicar** sobre un `.tres` en Sistema de archivos, asigna un ID nuevo en el Inspector y regístralo en el array correspondiente de `data/catalog.tres`. Arrastra el mismo archivo al mazo o al equipo. No registres dos Resources distintos con el mismo ID. Las guías `COMO_CREAR_*.md` detallan cada caso.

Puedes crear un recurso desde cero con **Nuevo recurso → RpgCardDefinition / RpgCharacterDefinition / RpgEnemyDefinition / RpgStatusDefinition**. Los efectos son **RpgEffectDefinition** y las acciones enemigas **RpgIntentDefinition**. Los desplegables limitan los tipos de acción admitidos, pero una regla completamente nueva requiere un módulo GDScript y sus pruebas.

## Validación y límites
Pulsa **Validar contenido** antes de jugar. Detecta IDs repetidos, referencias ausentes, mazos ajenos, recursos nulos, estados desconocidos y estadísticas inválidas. Si el juego recibe un catálogo inválido, muestra sus errores y evita iniciar combate, sin cambiar tus archivos. Los mensajes de validación no equivalen a una prueba de balance.

`data/catalog.tres` es la fuente activa. `data/content.json` y `visuals/profiles/catalog.json` se conservan como referencia de la migración, **no se leen para ejecutar el juego**. Los scripts `tools/convert_legacy_content.py` y `tools/bake_legacy_stage.py` documentan el traslado original y se niegan a sobrescribir sus salidas; no forman parte del arranque y no deben ejecutarse para editar contenido nuevo.

Las pruebas guardan y recargan escenas/Resources temporales y comprueban su comportamiento en juego. No se ha realizado una sesión gráfica manual en esta máquina ni pruebas de exportación o dispositivos. El guardado de `.tres` y `.tscn` guarda el proyecto, no una partida: el guardado de expedición se describe en `documentation/ROGUELIKE_Y_GUARDADO.md`.

El panel incorpora accesos a la configuración de expedición y a sus pantallas. La raíz Main permite asignar otro Expedition Rules. Los cambios de reglas se aplican al iniciar una partida nueva; las guardadas mantienen sus definiciones originales.

El panel permite crear y duplicar Resources con validación previa. Consulta [HERRAMIENTAS_DE_CONTENIDO.md](HERRAMIENTAS_DE_CONTENIDO.md) para el flujo actualizado.

## UI y ventanas de fase 6

La interfaz y la expedición incorporan un `Scroll` por encima de `Margin`: las rutas literales anteriores `Margin/...` pasan a `Scroll/Margin/...`, conservando los nombres únicos. Ajusta márgenes y estilos en esas mismas escenas. La nueva pantalla editable es `scenes/settings/settings.tscn`. Las ventanas de herramientas limitan su tamaño y desplazan su contenido, dejando Aplicar/Cancelar accesibles. Consulta [FASE_6_MULTIPLATAFORMA.md](FASE_6_MULTIPLATAFORMA.md). Se generaron un EXE y un APK de depuración; su revisión en dispositivos reales permanece pendiente.

La fase 8.1 añade categorías de biomas y reliquias al panel; el botón Expedición abre ahora `data/progression/expanded_expedition.tres`. Su configuración anterior sigue disponible. Consulta [la guía de expansión](FASE_8_BIOMAS_Y_RELIQUIAS.md).
