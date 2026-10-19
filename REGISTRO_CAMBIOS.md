# Registro de cambios
## Fase 1 — Umbral de Nácar
- Proyecto Godot 4.6.3 con Compatibility, formato horizontal adaptable y sin dependencias externas.
- Reglas permanentes en AGENTS.md y separación de datos, combate y presentación.
- Menú y combate real con energía, escudo, curación, descarte, reciclado y finales.
- Suelo 3D, cámara ortográfica y dos sprites provisionales originales.
- Pruebas automatizadas del modelo y recorrido de escena; documentación de personalización en español.
- Pendiente: contenido completo, estrés, roguelike, guardado y exportación verificada.

## Fase 2 — Combate extensible
- Cinco módulos de efectos con registro y validación de destinos, separados del modelo.
- Selección de carta, descripción y confirmación/cancelación de objetivo; fila desplazable para manos grandes.
- Ocho cartas y doce entradas en el mazo; robo adicional, energía y agotamiento.
- Tres enemigos elegibles con patrones de ataque, escudo y curación anunciados.
- Escudo enemigo y conservación de cartas durante resolución y reciclado.
- 53 comprobaciones del modelo y recorrido automatizado de la escena sin errores en Godot 4.6.3.
- Sin exportaciones ni pruebas visuales/táctiles reales; equipo, estados y estrés corresponden a fase 3.

## Fase 3 — Personajes, estados y estrés
- Selección de 1–3 integrantes; Lira y Noa disponibles, con 14 cartas y mazos individuales combinados (19 entradas).
- Estado y energía por personaje, ataque/defensa, pasivas configurables y especiales como cartas agotables.
- Apoyo dirigido, Resonancia y Protección temporales, acumulación de estrés y crisis individual; carta de calma.
- Ataques enemigos con objetivo anunciado, caída de integrantes y derrota solo al perder a todos.
- Presentación por actor con tintes distintos y ocultación de caídos; documentación y migración de catálogo v2.
- Pruebas: 53 comprobaciones anteriores, 54 de personajes y 7 de escena. Pendientes revisión visual y pruebas en dispositivos; sin exportaciones nuevas.

## Fase 4 — Animación y presentación 2.5D
- Controlador reutilizable de nueve estados, SpriteFrames opcionales y perfiles Resources editables.
- Ilustraciones provisionales originales para Noa y enemigo; conservado el recurso anterior de Lira.
- Cámara con deriva suave, profundidad, columnas, cristales y luz ambiental sin sombras dinámicas.
- Objetivos resaltados; números y anillos con deltas reales, animaciones por destinatario, especiales y crisis.
- Eventos de presentación independientes de las reglas; colas y efectos limitados, limpieza al reiniciar y poses finales.
- Importación y 153 comprobaciones sin fallos: 107 de reglas, 39 de presentación y 7 de escena. Documentación de personalización actualizada. No se han probado FPS, exportaciones ni la composición visual en esta máquina.

## Fase 4.1 — Edición visual antes del roguelike
- Catálogo activo `data/catalog.tres`, con cartas, efectos, personajes, enemigos, intenciones y estados Resources tipados para el Inspector.
- Conservados IDs, estadísticas, mazos, efectos y comportamiento del contenido anterior; JSON preservado como referencia y prueba de migración.
- Escenario, cámara, luz, tres posiciones de aliados, enemigo y personaje visual en escenas `.tscn`; no se reconstruyen al ejecutar.
- Menú/HUD persistentes, plantillas de carta/botón/fila y tema editable; ilustraciones de cartas y vista previa en el editor.
- Panel local Contenido con accesos a recursos, escenas y errores recuperables. Sin herramientas externas obligatorias.
- Pruebas de guardado/recarga de Resources y escenas: daño, costes, estadísticas, cámara, geometría, posiciones, imágenes y controles funcionan tras editarlos.
- Importación con complemento habilitado y 190 comprobaciones sin fallos. Guías actualizadas en español. Se mantiene pendiente una revisión gráfica manual, exportaciones y dispositivos; aún no se implementa roguelike.

## Fase 5 — Expedición roguelike
- Mapa conectado reproducible de cinco etapas con combates, élites, eventos, descanso, tienda, tesoros y jefe.
- Oro, cartas adquiridas y mejoras por ID; vida y estrés persistentes entre encuentros, sin alterar el catálogo del proyecto.
- Configuración RpgRunDefinition y jefe Resources; pantalla y plantilla de nodos editables con vista previa del mapa.
- Nueva/continuar expedición, semilla y resumen; conservados los combates de entrenamiento anteriores.
- Guardado local versión 1 con instantánea de contenido, combate completo y RNG; validación, temporal, copia anterior y recuperación de archivos dañados.
- Pruebas de expedición real completa, flujo de botones, carga exacta, economía, élites/eventos, versión incompatible y edición visual persistida.
- Importación con complemento y 280 comprobaciones sin fallos, incluidas las suites anteriores y dos recorridos completos con combates reales.
- Pendientes revisión gráfica manual, exportaciones/dispositivos, reliquias, biomas y metaprogresión.

## Fase 7 — herramientas antes de 6 y 8
- Búsqueda, filtros, creación/duplicación sin sobrescritura, previsualización, errores seleccionables, guardado y registro reversible.
- Recompensas y eventos editables como Resources; compatibilidad con instantáneas anteriores de versión 1.
- Pruebas de herramientas y guía de edición en español. Sin cambios de exportación ni expansión de biomas/reliquias.

## Ampliación de fase 7 — mazos, eventos y rutas
- Formularios con borradores validados y registro reversible: copias, orden y especial de mazos; texto y efectos de decisiones; tipos, enemigos y conexiones de rutas.
- `RpgRouteNode` y rutas personalizadas opcionales, con dos carriles, 4–8 etapas y jefe final. Las instantáneas anteriores conservan el generador procedural.
- Pruebas de formularios, persistencia y recorrido personalizado completo; documentación de edición en español.
- Verificación: 414 comprobaciones sin fallos, incluidas 15 del plugin con historial nativo; importación correcta en Godot 4.6.3. Arrastre físico y disposición gráfica pendientes de revisión.

## Fase 6 — UI y base multiplataforma
- Ventanas del editor acotadas con desplazamiento; UI de juego desplazable con cabeceras ajustadas, acciones en flujo, foco y zonas seguras.
- Pantalla de ajustes editable, preferencias independientes, perfiles gráficos, límites 30/60 FPS, movimiento/efectos y pantalla completa PC. Atajos y gestión de Atrás/pausa/cierre conservan las reglas y guardados anteriores.
- Presets Windows x86_64 y Android arm64, preparación reproducible de herramientas con comprobación de integridad. Windows EXE/PCK y APK de depuración generados localmente; sin publicar binarios ni clave de producción.
- 458 comprobaciones sin fallos y siete comprobaciones adicionales por paquete Windows/Android en Linux. ConfigFile emite un diagnóstico esperado en su prueba de archivo malformado. Revisión visual, ejecución en dispositivos y mediciones pendientes.

## Fase 8.1 — biomas, reliquias y contenido
- Dos tramos de bioma con pools de encuentros/eventos y ambiente visual, cuatro reliquias acumulables de expedición y categorías/asistentes de edición.
- Seis cartas nuevas sin cambiar mazos iniciales, un cuarto enemigo de entrenamiento y dos eventos; veinte cartas en total y jefe conservado.
- Snapshot opcional de expansión, inventario único, validación y continuidad exacta comprobada con fixtures reales de fase 6.
- 596 comprobaciones sin fallos, incluidas 130 de expansión. La fase 6 fue comprobada por el usuario en Android y PC, con 60 FPS estables en su PC; revisión física y balance de esta ampliación pendientes.
