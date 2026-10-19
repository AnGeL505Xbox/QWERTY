# Reglas de personajes y estrés — Fase 3
## Turnos y objetivos
Al iniciar un combate, se combinan los mazos de los integrantes seleccionados. La mano y descarte son compartidos, la energía es individual. El orden de selección determina el primer aliado vivo que atacará el enemigo; la intención muestra su nombre. Las cartas del personaje caído quedan en el mazo y la mano, pero no pueden jugarse. Se descartan normalmente al terminar turno; no se pierden cartas silenciosamente. No hay resurrección.

Los ataques y apoyos tienen propietario. `self` afecta al dueño, `ally` permite elegir cualquier aliado vivo, incluido el dueño. Una carta de apoyo nunca consume la energía de su destinatario. Derrota requiere que no quede ningún aliado vivo; victoria requiere que el enemigo llegue a cero de vida.

## Estadísticas y pasivas
Daño de carta = valor base + ataque efectivo del dueño. Para recibir un ataque: se resta defensa efectiva, después se consume escudo y finalmente vida. No se genera daño negativo. La energía se repone al inicio de cada turno individual y no se conserva entre rondas. Todos los integrantes tienen turno simultáneo dentro de la fase del jugador.

Noa tiene ataque 1, defensa 1 y pasiva de 1 de escudo al empezar turno. Lira conserva las estadísticas de la fase 2 (ataque/defensa 0). Las pasivas admitidas son `start_block` y `stress_relief`, valores no negativos. Un tipo nuevo de pasiva exige su regla y pruebas; no se evalúa código desde los datos de contenido.

## Estrés y crisis
Cada punto de vida perdido añade un punto de estrés hasta `stress_limit`. El daño absorbido no añade estrés. Curar vida no lo elimina; `calm` sí. Al iniciar turno, si un integrante vivo alcanzó su umbral, se marca CRISIS, se resta `crisis.energy_loss` de su energía (mínimo cero) y se reduce estrés en `crisis.relief`. La crisis se reevalúa en cada turno; no impide jugar cartas que se puedan pagar.

Lira: umbral 10, pierde 1 de energía, alivia 6 de estrés. Noa: umbral 8, pierde 2, alivia 5. Las diferencias son datos, no clases distintas. Después de la evaluación se aplican las pasivas de escudo y alivio. `crisis` se limpia al siguiente inicio antes de evaluar otra vez.

## Estados temporales
`statuses` define nombre y modificadores enteros de `attack` o `defense`. Resonancia suma 2 de ataque y Protección 2 de defensa; Fragilidad demuestra un modificador negativo configurable, pero aún no tiene carta ni aplicación enemiga. Los valores efectivos no bajan de cero.

Una aplicación de estado usa `amount` como duración en rondas, no como magnitud. Los estados nuevos se aplican inmediatamente. Tras la acción enemiga, se resta una ronda y se eliminan al llegar a cero. Un estado de duración 1 protege o potencia durante esta ronda y termina después del enemigo. Reaplicarlo conserva la mayor duración, sin sumar magnitudes. No se implementan aún estados sobre enemigos ni daño periódico.

## Migración del catálogo
El catálogo pasa de versión 1 a 2. El commit anterior de fase 2 conserva el punto de restauración; todos los IDs originales siguen existiendo. No hay guardados persistentes que migrar en esta fase.

Para trasladar contenido personalizado de fase 2:
1. Establece `version: 2`.
2. Mueve `starter_deck` a `deck` del personaje y `balance.energy` a su `energy`; elimina los campos globales duplicados.
3. Añade `owner` a cada carta. Solo el propietario puede incluirla en su mazo.
4. Completa las estadísticas, crisis, pasiva, especial, afinidad y color usando Lira como ejemplo.
5. Añade `team` (IDs de uno a tres personajes) y `statuses` (puede ser vacío si ninguna carta usa estados).
6. Ejecuta importación, validación del catálogo y pruebas. No renombres IDs sin revisar todas sus referencias.

La fase de edición visual sustituyó las aserciones de catálogo por mensajes recuperables y Resources editables. El panel Contenido valida antes de jugar. La migración JSON v1 → v2 de esta sección es histórica; la fuente activa actual es `data/catalog.tres`. La fase 5 incorpora guardado de expedición versión 1; consulta `ROGUELIKE_Y_GUARDADO.md`.

Los campos del Inspector `Crisis Energy Loss`, `Crisis Relief`, `Passive Start Block` y `Passive Stress Relief` se convierten a las definiciones de esta guía sin cambiar sus reglas. Consulta `EDICION_VISUAL.md`.
