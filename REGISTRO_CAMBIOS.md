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
