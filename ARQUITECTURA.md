# Arquitectura
- `core/data/catalog.gd`: adaptador del catálogo Resources a diccionarios de combate. `validator.gd` devuelve errores recuperables en editor y ejecución.
- `core/combat/battle.gd`: estado de un combate sin nodos, interfaz ni animaciones; generador aleatorio propio y señales `changed`/`action`, `actor_action(id, kind)` y `combat_event(event)` con deltas reales para presentación.
- `data/catalog.tres` y `core/data/resources/`: Resources tipados y su conversión a definiciones versionadas. El JSON anterior es solo referencia de migración. Los IDs son estables; no renombrarlos sin migración cuando exista guardado.
- `scenes/main.gd`: coordinación de señales entre modelo, interfaz y escenario. `scenes/ui/interface.gd` actualiza controles existentes e instancia plantillas de controles repetidos. Las reglas se ejecutan antes de emitir animaciones.
- `visuals/arena.gd`: cámara de perspectiva, escenario por capas, actores orientados a cámara y traducción de eventos visuales. Presentación independiente.
- `tests/`: reglas y recorrido automatizado de la escena.

`core/effects/registry.gd` declara módulos por efecto y destinos compatibles. Cada módulo expone `apply(battle, amount)`. El modelo valida el objetivo y la energía antes de modificar el estado. Retira la carta de la mano antes de resolver efectos y la deposita en descarte o agotadas después; así el robo nunca recicla la carta que se está ejecutando.

`core/enemies/intent.gd` selecciona y ejecuta patrones deterministas por turno. El escudo enemigo dura hasta su siguiente acción; el del jugador hasta el inicio del próximo turno. La interfaz consulta `valid_targets`, muestra la descripción y requiere confirmación. El jugador selecciona de uno a tres personajes; el enemigo dirige su ataque al primer integrante vivo del orden de selección y lo anuncia al inicio del turno. No cambia de objetivo ocultamente.

Los efectos de una carta comparten destino: no se permiten combinaciones de daño enemigo y curación propia en la misma carta todavía. El catálogo valida tipos, destinos y referencias antes de jugar, tanto en depuración como en una ejecución de distribución. El formato de contenido es versión 2: cartas con `owner`, mazos y energía por personaje, `team` y `statuses`. Se conservan los IDs anteriores. La migración se documenta en `documentation/PERSONAJES_Y_ESTRES.md`; no hay archivos de guardado que migrar todavía.

No introducir servicios, autoloads ni carpetas vacías sin necesidad. Nuevos módulos de progresión y guardado se incorporarán por fases con pruebas y formatos versionados.

## Personajes y estados
`core/characters/character.gd` mantiene una copia de la definición y estado individual: vida, energía, escudo, estrés y estados temporales. `core/status_effects/statuses.gd` calcula modificadores y expira duraciones. Las pasivas admiten escudo inicial y alivio de estrés; la crisis tiene umbral, pérdida de energía y alivio configurables.

`Battle.play` distingue `source_actor` (dueño, paga el coste) de `target_actor` (aliado que recibe apoyo). Los módulos de curación, escudo y calma usan el destinatario; energía y robo siguen perteneciendo al dueño/equipo. Los estados reciben el efecto completo con identificador y duración. Todos los efectos de una carta siguen compartiendo la misma clase de destino.

`health`, `max_health`, `block` y `energy` de Battle conservan acceso al primer integrante para los consumidores antiguos. La interfaz nueva utiliza `team`; no usar esos accesos para lógica de equipo nueva.

## Presentación de fase 4
`visuals/animations/profile.gd` define Resources editables en el Inspector; Los campos Visual Profile de los Resources de personaje/enemigo vinculan cada identidad con un perfil; el catálogo visual JSON anterior ya no se lee. `visuals/animations/actor.gd` controla nueve estados de AnimatedSprite3D con respaldo procedural y cola limitada. `visuals/effects/feedback.gd` limita y libera efectos. Arena sincroniza estados finales y resaltado. Los tres slots y el enemigo se instancian en `scenes/visuals/arena.tscn` y se reinician entre combates, conservando los transforms editados.

Las reglas emiten eventos después de resolverse; ninguna animación devuelve daño ni bloquea turnos. El controlador se puede sustituir sin modificar efectos o mazos. Ver `documentation/PRESENTACION_2_5D.md`.

## Edición visual antes del roguelike
El catálogo Resources mantiene el formato de diccionarios de versión 2 que ya consumía Battle. `RpgContentCatalog.to_dict()` excluye perfiles e ilustraciones; esos recursos se entregan a Arena y a la interfaz por rutas de presentación separadas. El código de reglas no tuvo que reescribirse.

La escena principal instancia `scenes/visuals/arena.tscn` y `scenes/ui/interface.tscn`. La primera serializa geometría, cámara, luz y slots; la segunda serializa menú, HUD, márgenes y acciones. La carta, botones y filas son PackedScene intercambiables, con estilos en `theme.tres`. Las animaciones solo reinician Pivot; VisualOffset y los marcadores son ajustes permanentes.

Los scripts `@tool` ofrecen vista previa de Actor y de la plantilla de carta. El complemento local `addons/content_editor/` permite seleccionar definiciones, abrir escenas y mostrar errores. No escribe Resources ni regenera escenas automáticamente.

`tools/convert_legacy_content.py` y `tools/bake_legacy_stage.py` documentan la migración inicial y rechazan sobrescrituras. No son dependencias del juego. No crear una segunda fuente activa de contenido ni un importador que reemplace cambios del usuario al arrancar.

## Roguelike y guardado — Fase 5
`core/progression/route.gd` genera un grafo conectado por semilla. `expedition.gd` es una máquina de fases sin nodos: mapa, combate, recompensa, descanso, tienda, evento, victoria o derrota. Mantiene una copia propia del contenido y aplica mejoras al generar datos de combate; no modifica Resources del proyecto.

`RpgRunDefinition` configura recorrido y economía desde `data/progression/expedition.tres`. El jefe tiene su propio Resource. `scenes/exploration/` contiene pantalla de expedición, gráfico de ruta y plantilla de nodo. La interfaz emite decisiones; el modelo comprueba fase, conectividad, ofertas, límites y coste antes de aplicarlas.

Battle acepta vida/estrés iniciales opcionales y exporta/restaura su estado sin introducir nodos ni dependencias de disco. `core/save_system/store.gd` conserva el payload versionado con checksum, temporal, copia anterior y recuperación; `run_validator.gd` comprueba la instantánea antes de cargar. Los RNG de combate y expedición se serializan como texto de 64 bits. Las animaciones se reconstruyen desde el estado cargado y no se serializan.

Main coordina ambas interfaces y autosalva en cambios reales del modelo; seleccionar una carta no modifica ni escribe la partida. El entrenamiento conserva su flujo anterior. Consulta `documentation/ROGUELIKE_Y_GUARDADO.md` para contrato de persistencia y futuras migraciones.
