# Expediciones roguelike y guardado — Fase 5
## Jugar una expedición
1. Abre `project.godot` con Godot 4.6.3 y pulsa F5.
2. Selecciona el equipo y escribe una semilla de 0 a 2147483647, por ejemplo **42**. Vacío genera una nueva semilla.
3. Pulsa **Nueva expedición**. Existe un solo espacio de guardado: comenzar otra reemplaza la anterior; la copia de recuperación conserva el estado previo a la última escritura.
4. Elige un nodo habilitado del mapa. Las líneas muestran los caminos entre etapas; no se pueden saltar etapas ni repetir nodos.
5. Juega el combate habitual. Tras victoria o derrota, pulsa **Continuar expedición** para ver recompensas o resumen.
6. **Guardar y volver al menú** y **Continuar expedición** permiten interrumpir y reanudar. El entrenamiento anterior contra enemigos sigue disponible y no altera el guardado de expedición.

## Recorrido inicial
Cinco etapas, con dos opciones por etapa y un jefe final común. La primera etapa es de combate. Las intermedias pueden ser combate, evento, tesoro, descanso o tienda. En el recorrido por defecto hay una etapa de descanso/tienda y una elección de élite/combate antes del jefe. Con cuatro etapas, la elección de élite tiene prioridad sobre la de descanso/tienda.

La generación usa un RandomNumberGenerator propio y la semilla elegida. Repetir semilla, equipo, contenido, configuración y decisiones reproduce la expedición en esta versión de Godot. El mapa completo y los estados RNG se guardan; la animación no consume ese generador.

Los élites utilizan una plantilla normal con +12 PV y +2 a sus ataques; otorgan 8 de oro adicional. El jefe **Guardián del umbral** tiene un Resource independiente y alterna ataque de 8, escudo de 8 y ataque de 12. Su presentación reutiliza el gráfico provisional enemigo.

## Progresión y decisiones
- Cada combate normal ganado o tesoro añade 12 de oro y permite elegir una recompensa: una copia de carta, una mejora elegible o conservar el mazo.
- Las cartas ofrecidas pertenecen a integrantes del equipo. La copia adquirida se añade al mazo de su dueño; no modifica el catálogo del proyecto.
- Las mejoras afectan todas las copias del mismo ID durante esa expedición. Cada nivel añade 2 a los efectos de daño, escudo, curación y calma; máximo 3 niveles. No cambian coste, robo, energía ni duración de estados. La descripción muestra el incremento además del texto base.
- Descanso: curar hasta +8 PV y aliviar hasta 6 de estrés a cada integrante vivo, o mejorar una carta. Solo se toma una decisión. No revive caídos.
- Tienda: una copia de carta cuesta 10 de oro y una mejora 15. Las ofertas de cartas se compran una vez; se pueden adquirir mejoras hasta el límite mientras quede oro. Se puede salir sin gastar.
- Evento de la fuente: recibir 18 de oro a cambio de perder hasta 3 PV por integrante vivo (el daño real genera estrés), o recuperarse. El riesgo puede causar derrota.

Vida, estrés, cartas, oro y mejoras persisten entre encuentros. Escudo, energía y estados temporales se reinician al comenzar el siguiente combate. Las crisis se evalúan con el estrés conservado. Derrota exige perder a todo el equipo; vencer al jefe completa la expedición. No hay desbloqueos permanentes ni metaprogresión todavía.

## Edición visual
El panel **Contenido** incorpora **Expedición: configuración** y **Mapa y recompensas**. **Validar contenido** comprueba también las reglas del recorrido. Si usas un catálogo o una configuración personalizados, selecciónalos en el Inspector y actualiza la lista antes de validar.

| Archivo/nodo | Qué se edita |
| --- | --- |
| `data/progression/expedition.tres` | Etapas, pool de encuentros, jefe, tipos intermedios, oro, precios, descanso, evento, élites y mejoras |
| `data/progression/boss.tres` | Vida, patrón, nombre y perfil visual del jefe |
| `scenes/exploration/run_ui.tscn` | Pantalla de mapa, grupo, inventario, mensajes, recompensas y acciones |
| `scenes/exploration/node_button.tscn` | Apariencia y tamaño de los nodos generados |
| `run_ui.tscn` → Route | Step, Origin, Connection Color, Preview Rules y Preview Seed |
| `scenes/ui/interface.tscn` | Semilla, nueva/continuar expedición y acciones al acabar combate |
| `scenes/main.tscn` → Main | Catálogo, Expedition Rules y Save Path |

Los encuentros de la configuración deben ser los mismos Resources registrados en **Enemies** del catálogo; sus estadísticas se toman de ese catálogo. El jefe se define directamente en Boss y se incorpora solo a la expedición, conservando el catálogo de entrenamiento. Usa un ID único para un jefe nuevo.

El mapa muestra una vista previa de semilla en el editor. Sus nodos se generan dinámicamente y no se guardan como nodos individuales: modifica la plantilla, Step y Origin para cambiar su aspecto. No muevas los botones generados manualmente. En ejecución se usa la semilla de la partida, no Preview Seed. Las listas de recompensas se rellenan desde la plantilla ActionButton, conservando el tema compartido.

Los cambios de contenido y reglas se aplican al comenzar una expedición nueva. Una partida cargada usa la copia de definiciones y reglas con la que empezó, para conservar coherencia. Los gráficos disponibles pueden actualizarse sin cambiar sus reglas guardadas.

## Guardado local y recuperación
Ruta predeterminada: **`user://expedition.json`**, en el directorio de datos del usuario que Godot elige en cada plataforma. En PC puede abrirse desde **Proyecto → Abrir carpeta de datos del usuario**. No se guarda dentro del repositorio. No requiere conexión ni permisos de almacenamiento externo de Android.

Se guarda automáticamente al crear expedición, entrar o resolver un nodo y después de cada carta o final de turno. Seleccionar o cancelar una carta no escribe archivos. Volver al menú también conserva el estado. Si una escritura falla, aparece un mensaje; la partida continúa, pero ese cambio no está persistido.

El formato de archivo **versión 1** contiene JSON con payload y checksum SHA-256. Conserva:
- Equipo, vida, estrés, mazos, oro y mejoras.
- Mapa, historial, nodo activo, fase y ofertas pendientes.
- Definiciones de contenido y reglas de la expedición.
- Combate en curso: mano, robo, descarte, agotadas, energía, escudo, estados, intención, turno y resultado.
- Semilla y estado de ambos generadores como cadenas decimales para conservar sus enteros de 64 bits al pasar por JSON.

Primero se escribe y vacía `.tmp`; se conserva la versión anterior en `.bak` y se renombra el temporal. Si una interrupción deja el principal ausente o inválido, **Continuar** intenta la copia `.bak` y muestra un aviso de recuperación. Esa copia puede estar una acción por detrás. Un principal inválido se conserva como `.corrupt_<marca>` antes de una nueva escritura válida; no se rota sobre la copia buena.

La carga comprueba estructura, versión, checksum, referencias, ruta conectada, valores, intención y conservación de cartas. Un archivo incompatible se conserva y muestra un error; no se inventa una partida para sustituirlo. El primer formato no necesita una migración desde versiones anteriores, porque no existían guardados antes de fase 5. Futuras versiones deben añadir una migración explícita antes de validar, con pruebas y conservación del original. Si cambia el algoritmo de rutas, también hay que versionarlo o migrar su validación.

El guardado de partida es independiente de guardar `.tres` y `.tscn` en el editor. Aún no incluye opciones globales, reliquias, equipo o desbloqueos: sus sistemas no existen todavía.

## Verificación y límites
Las pruebas recorren una expedición completa con cartas y turnos reales, prueban entrada por botones, guardado intermedio, continuidad exacta, recuperación de copia, versiones incompatibles, economía, mejoras, estados de derrota y edición persistida de configuración/mapa. Las pruebas usan archivos `test_roguelike*` separados del espacio del jugador.

La validación se realiza sin renderizado gráfico. Sigue pendiente revisar composición, tacto, exportaciones y rendimiento real en Windows/Android. El recorrido y los eventos son cortos; reliquias, biomas, narrativa ramificada, eliminación de cartas y metaprogresión quedan preparados como ampliaciones, no implementados.

## Edición de rutas y decisiones

El panel Contenido incluye formularios de eventos y rutas: véase [la guía de editores](../EDITORES_DE_MAZOS_EVENTOS_Y_RUTAS.md). Con `route_nodes` vacío se conserva el generador original. Una ruta personalizada mantiene tipos, coordenadas y conexiones, y resuelve enemigos automáticos por semilla. La configuración guardada incluye el campo opcional solo cuando hay una ruta personalizada. Los guardados anteriores siguen usando su algoritmo original y no se actualizan al modificar Resources. Las decisiones modernas se editan en `events`; `event_gold` y `event_damage` se conservan para la fuente de partidas/configuraciones anteriores sin esa lista.
