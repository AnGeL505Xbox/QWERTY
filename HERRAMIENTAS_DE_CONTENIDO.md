# Fase 7: herramientas de contenido

Implementada antes de las fases 6 y 8. Abre el proyecto con Godot 4.6.3. En **Proyecto → Ajustes del proyecto → Plugins**, activa el editor de contenido si no aparece el panel **Contenido**.

## Crear y duplicar

1. Busca por nombre, ID o ruta y filtra por categoría. Selecciona un elemento para editarlo en el Inspector.
2. Pulsa **Crear recurso…** o **Duplicar selección…**. El asistente muestra los archivos propuestos y los errores antes de habilitar Crear. Los IDs usan minúsculas, números y guion bajo, comenzando por letra.
3. Ajusta el recurso en el Inspector, pulsa **Validar contenido** y después **Guardar contenido**. Los errores seleccionables abren el recurso relacionado. Las modificaciones de escenas se guardan desde el editor de escenas.
4. Ejecuta una expedición nueva para probar contenido actualizado. Continuar una partida usa su instantánea anterior.

Se admiten cartas, personajes, enemigos, estados, tablas de recompensas y eventos. Los archivos nuevos van a `data/<categoría>/<id>.tres`; el asistente nunca sobrescribe uno existente. Una carta nueva requiere propietario; se registra en el catálogo, pero debes añadirla al mazo del personaje si quieres que sea inicial. Crear un personaje genera cartas básicas y especial; duplicarlo copia sus cartas y efectos con IDs y propietario nuevos. Añade el personaje a `team` o selecciónalo en el menú para usarlo. Un enemigo se registra para entrenamiento; añádelo también a `encounters` en la expedición si debe aparecer en rutas.

El registro en catálogo/reglas admite Deshacer/Rehacer del editor. Deshacer conserva los archivos creados: permite recuperarlos desde FileSystem. Guarda de nuevo para persistir un registro deshecho. No se borran archivos automáticamente. El guardado global valida antes de escribir y comunica fallos; si falla una escritura, otros archivos pueden haberse guardado. Mantén commits pequeños.

**Vista previa de selección** muestra datos y, para cartas, abre su plantilla con `preview_card`. No guardes esa asignación temporal en la plantilla si no deseas cambiar su previsualización predeterminada. Las tablas inactivas no aparecen en la lista: ábrelas desde FileSystem y asígnalas a `reward_table` para activarlas.

## Recompensas editables

`data/progression/expedition.tres` referencia `data/rewards/standard.tres`:

- `card_choices` y `upgrade_choices`: de 0 a 5 ofertas de cada tipo, limitadas por candidatos disponibles.
- `cards`: pool opcional; vacío usa cartas elegibles del equipo. No cambia las cartas de la tienda.
- `allow_skip`: ofrece omitir. Si no hay ofertas válidas, siempre se permite salir para evitar bloqueos.

Al crear una tabla puedes activarla con la casilla del asistente. Crear otra sin activarla conserva la anterior.

## Eventos editables

La lista `events` de la expedición referencia Resources `RpgEventDefinition`; cada entrada tiene ID, nombre, descripción y de 1 a 8 `RpgEventChoice`. Cada opción tiene ID, texto, variaciones de oro/PV/estrés y una carta opcional. El oro negativo exige fondos suficientes; la carta exige propietario en el equipo. Los PV y estrés afectan a todos los integrantes vivos, con sus límites; el daño añade estrés además del cambio indicado. Una opción letal puede terminar la expedición. Siempre hay una salida sin efecto.

Duplica la fuente existente o crea un evento, edita sus opciones en el Inspector y guarda. Las nuevas expediciones eligen eventos con su RNG reproducible. Editar datos no cambia partidas en curso.

## Compatibilidad y pruebas

El sobre de guardado sigue en versión 1. Los nuevos campos de configuración son opcionales y se conservan en la instantánea. Las partidas antiguas sin `events`/`rewards` mantienen las decisiones originales de fuente, ofertas anteriores y consumo de RNG; no se les incorporan reglas nuevas al cargar.

Ejecuta `godot --headless --path . --script tests/authoring.gd`. Comprueba creación/duplicación, archivos protegidos, guardado aislado, validación, ofertas configuradas, eventos y compatibilidad anterior. Usa `data/.editor-tests/` ignorado por Git y lo limpia al terminar. La regresión completa está en README. Las comprobaciones sin ventana no sustituyen la revisión de disposición del panel y Deshacer/Rehacer en una sesión gráfica.

Reliquias, biomas, metaprogresión y exportaciones reales siguen pendientes; no forman parte de esta fase.

## Editores especializados

El panel incorpora edición de mazos, formularios de decisiones y un grafo de rutas. Consulta [EDITORES_DE_MAZOS_EVENTOS_Y_RUTAS.md](EDITORES_DE_MAZOS_EVENTOS_Y_RUTAS.md) para el flujo, restricciones y compatibilidad.
