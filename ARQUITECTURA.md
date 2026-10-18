# Arquitectura
- `core/data/catalog.gd`: carga y comprobaciones de integridad del JSON, ejecutadas en editor/pruebas de depuración.
- `core/combat/battle.gd`: estado de un combate sin nodos, interfaz ni animaciones; generador aleatorio propio y señales `changed`/`action`.
- `data/content.json`: catálogo versionado y balance. Los IDs son estables; no renombrarlos sin migración cuando exista guardado.
- `scenes/main.gd`: menú, botones y representación del estado. Las reglas se ejecutan antes de emitir animaciones.
- `visuals/arena.gd`: cámara ortográfica, suelo 3D y sprites orientados a cámara. Presentación independiente.
- `tests/`: reglas y recorrido automatizado de la escena.

En esta fase, los efectos son tres operaciones en `Battle.play`. La fase 2 separará sus resolutores antes de añadir estados complejos. La selección de objetivos es automática porque solo hay un personaje y un enemigo; no hay selección táctica de equipo todavía.

No introducir servicios, autoloads ni carpetas vacías sin necesidad. Nuevos módulos de progresión y guardado se incorporarán por fases con pruebas y formatos versionados.
