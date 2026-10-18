# Arquitectura
- `core/data/catalog.gd`: carga y comprobaciones de integridad del JSON, ejecutadas en editor/pruebas de depuración.
- `core/combat/battle.gd`: estado de un combate sin nodos, interfaz ni animaciones; generador aleatorio propio y señales `changed`/`action` y `actor_action(id, kind)` para presentación individual.
- `data/content.json`: catálogo versionado y balance. Los IDs son estables; no renombrarlos sin migración cuando exista guardado.
- `scenes/main.gd`: menú, botones y representación del estado. Las reglas se ejecutan antes de emitir animaciones.
- `visuals/arena.gd`: cámara ortográfica, suelo 3D y sprites orientados a cámara. Presentación independiente.
- `tests/`: reglas y recorrido automatizado de la escena.

`core/effects/registry.gd` declara módulos por efecto y destinos compatibles. Cada módulo expone `apply(battle, amount)`. El modelo valida el objetivo y la energía antes de modificar el estado. Retira la carta de la mano antes de resolver efectos y la deposita en descarte o agotadas después; así el robo nunca recicla la carta que se está ejecutando.

`core/enemies/intent.gd` selecciona y ejecuta patrones deterministas por turno. El escudo enemigo dura hasta su siguiente acción; el del jugador hasta el inicio del próximo turno. La interfaz consulta `valid_targets`, muestra la descripción y requiere confirmación. El jugador selecciona de uno a tres personajes; el enemigo dirige su ataque al primer integrante vivo del orden de selección y lo anuncia al inicio del turno. No cambia de objetivo ocultamente.

Los efectos de una carta comparten destino: no se permiten combinaciones de daño enemigo y curación propia en la misma carta todavía. El catálogo valida tipos, destinos y referencias en modo depuración. El formato de contenido es versión 2: cartas con `owner`, mazos y energía por personaje, `team` y `statuses`. Se conservan los IDs anteriores. La migración se documenta en `documentation/PERSONAJES_Y_ESTRES.md`; no hay archivos de guardado que migrar todavía.

No introducir servicios, autoloads ni carpetas vacías sin necesidad. Nuevos módulos de progresión y guardado se incorporarán por fases con pruebas y formatos versionados.

## Personajes y estados
`core/characters/character.gd` mantiene una copia de la definición y estado individual: vida, energía, escudo, estrés y estados temporales. `core/status_effects/statuses.gd` calcula modificadores y expira duraciones. Las pasivas admiten escudo inicial y alivio de estrés; la crisis tiene umbral, pérdida de energía y alivio configurables.

`Battle.play` distingue `source_actor` (dueño, paga el coste) de `target_actor` (aliado que recibe apoyo). Los módulos de curación, escudo y calma usan el destinatario; energía y robo siguen perteneciendo al dueño/equipo. Los estados reciben el efecto completo con identificador y duración. Todos los efectos de una carta siguen compartiendo la misma clase de destino.

`health`, `max_health`, `block` y `energy` de Battle conservan acceso al primer integrante para los consumidores antiguos. La interfaz nueva utiliza `team`; no usar esos accesos para lógica de equipo nueva.
