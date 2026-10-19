# Editores de mazos, eventos y rutas

Abre el proyecto con Godot 4.6.3 y el plugin **Contenido** activo. Estas herramientas amplían la fase 7; las fases 6 y 8 siguen pendientes.

Todos los formularios trabajan sobre un **borrador**. **Aplicar borrador** valida los cambios y los registra en el editor con Deshacer/Rehacer. **Cancelar** cierra sin modificar el recurso. Después de aplicar, pulsa **Guardar contenido** en el panel. Deshacer después de guardar requiere guardar de nuevo para actualizar los archivos. Se conservan las referencias a cartas/enemigos registrados: editar un mazo no duplica las definiciones de sus cartas.

## Mazo de un personaje

1. Filtra por **Personajes**, selecciona uno y pulsa **Editar mazo del personaje…**.
2. A la izquierda aparecen sus cartas del catálogo, con búsqueda por nombre o ID. Arrástralas a la lista derecha o usa **Añadir copia →**. Cada entrada representa una copia; repetir una carta es válido.
3. Reordena arrastrando dentro del mazo o con **Subir/Bajar**. **Quitar copia** elimina solo la entrada seleccionada.
4. Elige su habilidad **Especial** en el desplegable. Puede ser una carta del personaje aunque no esté en su mazo inicial.
5. Comprueba el número de copias, cartas distintas y coste medio; aplica y guarda.

El orden inicial se conserva en los datos, pero el combate baraja el mazo por semilla. No se permiten mazos vacíos, cartas de otro propietario, especiales ajenos ni referencias a cartas sin registrar. Para crear una carta, utiliza primero el asistente existente. Las modificaciones se usan en entrenamiento y en expediciones nuevas.

## Decisiones de un evento

1. Filtra por **Eventos**, selecciona uno y pulsa **Editar evento seleccionado…**. Para uno nuevo, usa antes **Crear recurso… → Evento**.
2. Edita ID, nombre y descripción. Conserva los IDs existentes salvo que desees renombrarlos deliberadamente.
3. Selecciona una decisión de la lista para editar ID, texto del botón, oro, PV, estrés y carta opcional. Usa **+ Opción**, **Quitar** y **↑/↓** para organizar entre una y ocho decisiones.
4. Aplica y guarda. Las expediciones nuevas eligen un evento de la lista `events` con su RNG.

El oro negativo exige fondos suficientes. Los cambios de PV y estrés afectan a cada integrante vivo y se limitan a sus estadísticas; el daño real añade estrés además del valor indicado. Curar no revive. La carta requiere a su propietario en el equipo. El jugador siempre puede abandonar sin efecto.

Este editor trabaja con las decisiones de un evento individual. No añade cadenas de eventos ni condiciones narrativas nuevas. Una ruta con tipo Evento sigue eligiendo entre los eventos configurados en la expedición.

## Ruta de expedición

Pulsa **Editar rutas de expedición…**. Se utiliza la configuración de expedición abierta desde el panel, por defecto `data/progression/expedition.tres`.

- **Semilla de vista previa** permite revisar los resultados del generador. En modo procedural cambia los tipos y enemigos según las reglas anteriores; en modo personalizado conserva tipos y conexiones y cambia los enemigos automáticos.
- **Etapas para regenerar** admite de cuatro a ocho. Pulsa **Regenerar borrador** para construir un mapa nuevo con esa longitud y semilla. Esto reemplaza el borrador, no los datos ya guardados. Cambiar solo el número del control no redimensiona el mapa.
- Cada caja tiene tipo de nodo y selección de enemigo. Cambia entre Combate, Élite, Evento, Tesoro, Descanso y Tienda. El jefe ocupa siempre el último nodo.
- Para fijar un enemigo de Combate/Élite, elígelo entre los `encounters` de la expedición. **Enemigo automático** lo elige por semilla. El jefe usa la propiedad `boss` de la expedición.
- Arrastra desde el puerto derecho hacia un puerto izquierdo de la etapa siguiente. Se pueden quitar conexiones existentes desde sus puertos. No se admiten saltos de etapa, ciclos, enlaces duplicados, nodos inaccesibles ni caminos sin salida.
- Mover una caja solo organiza esta vista temporal. La posición del mapa de juego sigue determinada por etapa y carril.
- **Usar ruta procedural** descarta la ruta personalizada del borrador y prepara el generador anterior. Aplica y guarda para conservar ese cambio.

El formato actual mantiene **dos carriles por etapa y un único jefe final**. Todos los nodos deben ser accesibles desde alguna entrada; cada camino debe llegar al jefe. Editar una caja o conexión de una vista procedural convierte esa vista en una ruta personalizada. No convierte en fijos los enemigos automáticos. Crear enemigos nuevos sigue siendo tarea del asistente: regístralos también en `encounters` para ofrecerlos en este editor.

Las rutas personalizadas se guardan como `Array[RpgRouteNode]` en `route_nodes` de la configuración. No se modifica la escena del mapa ni el catálogo al aplicar una ruta.

## Partidas y compatibilidad

Los cambios de estos editores se usan al iniciar partidas nuevas. Continuar una expedición conserva sus mazos, eventos, mapa, configuración y RNG anteriores.

El sobre de guardado continúa en versión 1: `route_nodes` es un campo opcional de su instantánea de configuración. Su ausencia mantiene el generador anterior, con idéntico algoritmo y consumo de RNG. Una ruta personalizada se valida antes de iniciar/cargar y sus nodos resueltos se contrastan con la semilla y la configuración guardadas. No se requiere migrar partidas anteriores.

## Verificación

Ejecuta:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/editor_workflows.gd
godot --headless --editor --path . -- --test-content-editors
```

La prueba acciona formularios y señales, valida borradores, comprueba Deshacer/Rehacer de propiedades con `UndoRedo`, recarga Resources, guarda/restaura una expedición personalizada y completa su recorrido con cartas y turnos reales. Usa archivos `user://test_editor_workflows*`, separados de la partida del usuario. La batería completa sigue documentada en README.

La integración nativa se ejecuta en una instancia nueva del editor, abre los tres formularios desde el plugin y comprueba Aplicar/Deshacer/Rehacer mediante `EditorUndoRedoManager`, incluyendo la actualización de la lista. Usa copias en memoria y cierra esa instancia al terminar. El comando con `--test-content-editors` es una prueba, no una forma de abrir el editor para trabajar.

Resultado: 67 comprobaciones de flujos y 15 de integración nativa, además de las 332 anteriores, sin fallos. Las comprobaciones sin ventana verifican construcción, señales, datos e historial; la disposición gráfica y el arrastre con ratón requieren revisión en una sesión gráfica de Godot.
