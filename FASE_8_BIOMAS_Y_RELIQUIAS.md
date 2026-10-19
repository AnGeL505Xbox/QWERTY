# Fase 8.1: biomas, reliquias y contenido

Esta primera entrega de la fase 8 amplía las expediciones sin cambiar sus mazos iniciales. La configuración activa de Main y del panel **Contenido → Expedición** es ahora `data/progression/expanded_expedition.tres`. La anterior `data/progression/expedition.tres` permanece disponible como configuración de referencia, con su comportamiento anterior.

## Qué probar

1. Inicia **Nueva expedición**; Continuar conserva el contenido de tu partida anterior.
2. Recorre **Ruinas de nácar** (etapas 1–2) y **Jardín de ópalo** (etapas 3–5). Sus nombres aparecen en el mapa y el HUD; cambia la iluminación ambiental. La geometría del escenario se conserva.
3. Tras un combate no final o al abrir un tesoro, puedes elegir una reliquia como alternativa a cartas/mejoras. Se ofrece una del pool pendiente, sin repetir las que ya posees. Elegirla consume esa recompensa.
4. Consulta las reliquias y sus efectos en la expedición y en el HUD de combate. Guardar y continuar conserva el inventario y sus bonificaciones.

El catálogo tiene ahora **20 cartas, cuatro enemigos de entrenamiento y un jefe**. Las seis cartas nuevas aparecen en recompensas/tiendas y pueden añadirse a los mazos desde el editor; las diecinueve copias iniciales de Lira/Noa se conservan.

| Carta | Propietario | Energía | Efecto base |
|---|---|---|---|
| Estocada lunar | Lira | 2 | 13 daño |
| Paso de bruma | Lira | 1 | 5 escudo y robar 1 |
| Respiro de nácar | Lira | 0 | Aliviar 4 estrés; se agota |
| Farol compartido | Noa | 1 | 7 escudo y aliviar 2 estrés a un aliado |
| Marea reparadora | Noa | 2 | Curar 9 PV a un aliado vivo |
| Eco reflejado | Noa | 1 | 8 daño; se agota |

Se conservan los modificadores de ataque/defensa existentes. **Espinero de ópalo** alterna ataque 5, guardia 5 y ataque 7; tiene 30 PV y usa un perfil provisional verde basado en el recurso visual original. No incorpora arte final nuevo.

Los eventos adicionales son **Caravana extraviada**, en las ruinas, y **Archivo entre raíces**, en el jardín. El archivo permite obtener Paso de bruma para Lira a cambio de oro; esa opción se desactiva si Lira no forma parte del equipo. Se mantiene la salida sin efecto y la recuperación alternativa.

## Reliquias editables

| Reliquia | Bonificación para la expedición |
|---|---|
| Concha del umbral | +1 escudo por integrante vivo al iniciar cada turno |
| Brasa serena | +1 energía por integrante vivo cada turno |
| Semilla de ópalo | +3 PV por integrante vivo al ganar un combate |
| Medallón del caminante | +5 oro al ganar un combate |

Las bonificaciones de reliquias distintas se suman a las estadísticas/pasivas existentes; cada ID puede adquirirse una sola vez. El daño y la crisis siguen funcionando con las reglas anteriores. La curación se limita al máximo del personaje y no resucita. El oro/curación de victoria se aplican al completar el resultado del combate, incluido el jefe, una sola vez; no se conceden al abrir tesoros o al cargar. Las reliquias duran solo esa expedición.

Para crear otra, usa **Crear recurso… → Reliquia** en Contenido. El asistente genera un `.tres` y prepara su registro en `relics` de la expedición; puedes deshacerlo. Selecciona la reliquia y edita `turn_block`, `turn_energy`, `victory_heal` y `victory_gold` en el Inspector; valida y pulsa **Guardar contenido**. Los límites de cada campo están tipados y se validan al iniciar/cargar.

## Biomas editables

Selecciona un bioma desde la categoría **Biomas**. Sus Resources están en `data/biomes/`:

- `first_row` y `last_row` son inclusivos y comienzan en cero: 0–1 corresponde a etapas 1–2. Todos los tramos deben cubrir la expedición sin huecos ni solapamientos.
- `encounters` limita los enemigos del tramo. Arrastra los mismos Resources registrados en `encounters` de la expedición. Vacío usa el pool global. El jefe final sigue definido por `boss`.
- `events` limita los eventos del tramo y referencia los mismos Resources de la lista global `events`. Vacío usa los eventos globales.
- `color`, nombre y descripción controlan la identificación visual del tramo. Puedes desactivar el tinte del escenario con `Arena.biome_tint_enabled` en `arena.tscn`; los ajustes originales del Environment se restauran al volver al menú/entrenamiento.

**Crear recurso… → Bioma** y Duplicar generan archivos sin activarlos, para evitar solapar etapas automáticamente. Después arrastra el `.tres` a `biomes` de la expedición y ajusta los rangos de todos los tramos; valida y guarda. Los biomas inactivos se abren desde FileSystem. Sus arrays duplicados se independizan; enemigos y eventos mantienen sus referencias registradas.

El editor de rutas muestra el bioma de cada nodo y filtra los enemigos disponibles. Las conexiones y tipos siguen siendo editables. Si cambias el número de etapas, ajusta también los rangos de biomas; la validación bloqueará la ruta mientras no cubran las etapas nuevas. El rango de biomas determina su asignación tanto en mapas procedurales como en rutas personalizadas.

## Compatibilidad y arquitectura

El sobre de guardado sigue en versión 1. `biomes` y `relics` son campos opcionales de la instantánea de configuración; las partidas con pool de reliquias guardan además una lista de IDs adquiridos. Los nodos modernos incluyen su bioma. No se incorporan estos campos a una partida anterior al cargarla: mantiene su mapa, cartas, eventos, RNG y forma de estado originales.

`core/progression/relics.gd` calcula bonificaciones sobre las copias de combate; no modifica Resources ni los datos base de los personajes. `expansion_validator.gd` valida recursos convertidos y la cobertura/pools. El guardado valida IDs únicos, ofertas y la correspondencia entre nodos, semilla y configuración.

Las instantáneas de `tests/fixtures/phase6_*.json`, generadas con el código de la fase 6, comprueban restauración y siguiente turno idénticos. Las pruebas copian esos archivos antes de leerlos con Store para que una regresión no modifique los originales.

## Verificación y límites

Ejecuta `godot --headless --path . --script tests/expansion.gd`, además de las suites de README. Comprueba adquisición, acumulación, guardado/carga intermedia, pools agotados, datos inválidos, cartas nuevas, patrón del enemigo, interacción de botones y dos expediciones completas con cartas reales.

Resultado de código: 596 comprobaciones sin fallos, incluidas 130 de expansión. ConfigFile sigue mostrando un diagnóstico esperado en la prueba deliberada de preferencias malformadas. Las comprobaciones de paquetes/exportación se documentan aparte en `EXPORTAR_PC_ANDROID.md`.

El usuario confirmó funcionamiento de la fase 6 en Android y PC, con 60 FPS estables en su PC. No se especificaron dispositivos ni FPS Android. Esta ampliación requiere una nueva revisión visual, de balance y de rendimiento en esos equipos; las pruebas automáticas no sustituyen esa comprobación.

Quedan para entregas futuras más biomas/contenido, arte propio de cada región, sinergias avanzadas de reliquias y metaprogresión. Esta entrega no añade desbloqueos permanentes, comercio de reliquias, guardados en nube ni resistencias elementales nuevas.
