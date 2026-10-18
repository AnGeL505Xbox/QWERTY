# Presentación 2.5D — Fase 4
## Contrato entre reglas y presentación
El combate emite `combat_event` después de aplicar una acción. Contiene `source`, `animation` y una lista `changes` con destino y deltas reales de vida, escudo, estrés y nuevos estados. `state_snapshot` construye copias de valores de combate, sin nodos o recursos gráficos. Las señales anteriores `action` y `actor_action` se mantienen para consumidores existentes.

Arena escucha los eventos; nunca entrega resultados a Battle. Jugar cartas rápidas puede dejar animaciones pendientes, pero el estado de combate ya está resuelto. No se bloquean acciones mientras se animan sprites y no se consulta el final de un clip para calcular daño. La interfaz conserva el estado final y el objetivo enemigo anunciado.

Cada Actor tiene una cola de máximo ocho animaciones pendientes. Los estados finales se añaden después de los impactos pendientes, impiden nuevos movimientos y conservan su pose. La derrota sustituye la ocultación instantánea anterior. Desde la fase de edición visual, los actores son instancias de escena en slots permanentes. Cambiar de combate reinicia sus tweens, colas y estado final y limpia efectos; no se acumulan enemigos entre reinicios.

## Nueve estados
| Estado | Disparador | Respaldo procedural |
| --- | --- | --- |
| idle | Inicio y fin de acción sin resultado final | Respiración vertical |
| enter | Crear equipo o enemigo | Deslizamiento y aparición |
| attack | Carta ofensiva o ataque enemigo | Avance y retorno |
| defend | Carta de apoyo o guardia/curación enemiga | Contracción y recuperación |
| hurt | Pérdida real de vida | Retroceso y destello |
| special | Carta referenciada por `special` | Elevación y destello |
| crisis | Umbral de estrés al comenzar turno | Balanceo |
| victory | Ganador al cerrar combate | Salto breve y pose |
| defeat | Vida cero | Caída y atenuación |

El perfil `.tres` selecciona textura, color, SpriteFrames, nombres de clips, duración, escala por píxel y sentido del avance. El equipo mira hacia la derecha; el perfil enemigo usa `facing = -1`. La propiedad solo controla el movimiento del respaldo; el artista decide la orientación de los fotogramas.

## Límites y comprobaciones
La presentación utiliza una luz sin sombras, geometría ligera, texto 3D y anillos de baja segmentación. Hay como máximo 24 nodos transitorios de efectos, que se eliminan al terminar. El tiempo visual no utiliza el generador aleatorio del combate.

`tests/presentation.gd` comprueba los nueve estados, clips nativos, respaldo, objetivos, deltas reales, limpieza, límites y equivalencia de reglas con/sin presentación. Es una prueba sin renderizado gráfico: no demuestra composición visual, legibilidad, FPS ni compatibilidad efectiva en dispositivos. Revisar manualmente menú, tres integrantes, cartas, ambos resultados y sustitución de spritesheets antes de una distribución.

No se agregan sonidos ni arte final en esta fase. Perfiles de calidad, accesibilidad completa y exportaciones se mantienen en fase 6. Antes del roguelike se añadió la fase de edición visual descrita en `EDICION_VISUAL.md`; mapa, recompensas, mejoras y guardado versionado siguen pendientes.
