# Arquitectura
- `core/data/catalog.gd`: carga y comprobaciones de integridad del JSON, ejecutadas en editor/pruebas de depuración.
- `core/combat/battle.gd`: estado de un combate sin nodos, interfaz ni animaciones; generador aleatorio propio y señales `changed`/`action`.
- `data/content.json`: catálogo versionado y balance. Los IDs son estables; no renombrarlos sin migración cuando exista guardado.
- `scenes/main.gd`: menú, botones y representación del estado. Las reglas se ejecutan antes de emitir animaciones.
- `visuals/arena.gd`: cámara ortográfica, suelo 3D y sprites orientados a cámara. Presentación independiente.
- `tests/`: reglas y recorrido automatizado de la escena.

`core/effects/registry.gd` declara módulos por efecto y destinos compatibles. Cada módulo expone `apply(battle, amount)`. El modelo valida el objetivo y la energía antes de modificar el estado. Retira la carta de la mano antes de resolver efectos y la deposita en descarte o agotadas después; así el robo nunca recicla la carta que se está ejecutando.

`core/enemies/intent.gd` selecciona y ejecuta patrones deterministas por turno. El escudo enemigo dura hasta su siguiente acción; el del jugador hasta el inicio del próximo turno. La interfaz consulta `valid_targets`, muestra la descripción y requiere confirmación. Hay un único combatiente por bando; el sistema de equipo sigue pendiente.

Los efectos de una carta comparten destino: no se permiten combinaciones de daño enemigo y curación propia en la misma carta todavía. El catálogo valida tipos, destinos y referencias en modo depuración. El formato de contenido sigue en versión 1 porque aún no hay guardados; las nuevas entradas requieren `target`, `exhaust` y los enemigos `pattern`. Se conserva el ID de cada carta anterior.

No introducir servicios, autoloads ni carpetas vacías sin necesidad. Nuevos módulos de progresión y guardado se incorporarán por fases con pruebas y formatos versionados.
