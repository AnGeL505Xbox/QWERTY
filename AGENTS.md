# Reglas permanentes
- Desarrollar exclusivamente en este repositorio con Godot 4 y GDScript.
- Revisar la arquitectura y el estado Git antes de editar. Preservar trabajo y funcionalidades existentes.
- Trabajar por fases pequeñas en ramas; no modificar ni publicar la rama principal sin aprobación.
- Separar reglas de combate, datos, interfaz y presentación. Las animaciones nunca controlan las reglas.
- Usar identificadores estables y validar referencias. Mantener contenido editable y evitar duplicar lógica.
- Una base de código para PC y Android, sin servicios externos obligatorios. Considerar controles táctiles y rendimiento móvil.
- Mantener documentación en español y explicar cambios, pruebas, limitaciones y edición de contenido al entregar cada fase.
- Ejecutar importación, pruebas y arranque con Godot cuando esté disponible. No afirmar exportaciones o rendimiento sin pruebas reales.
- No incorporar recursos protegidos ni secretos. Documentar migraciones antes de cambios incompatibles.

## Edición visual
- El catálogo activo es `data/catalog.tres` y sus Resources tipados. `data/content.json` y `visuals/profiles/catalog.json` son referencias históricas; no editar como fuente activa.
- Mantener escenario, HUD y plantillas en escenas `.tscn`. No volver a reconstruir geometría, cámaras o controles persistentes por código, ni sobrescribir transforms/estilos editados al arrancar.
- Los controles repetidos se instancian desde PackedScene; conservar los nombres únicos y el contrato de nodos documentado. Usar VisualOffset para ajustes permanentes y Pivot para animación.
- Validar contenido con errores recuperables y comprobar que los cambios guardados del editor llegan al juego mediante `tests/visual_editing.gd`.

## Expediciones y persistencia
- Las reglas de recorrido y economía se editan en `data/progression/expedition.tres`; mantener sus pantallas/plantillas en `scenes/exploration/`.
- No modificar Resources del catálogo al obtener recompensas. Las partidas conservan su instantánea de datos y sus RNG; mantener compatibilidad o migración explícita al cambiar el formato o algoritmo de rutas.
- Conservar originales/copia de recuperación ante errores de carga. Las pruebas deben usar rutas de guardado diferentes de `user://expedition.json`.

## Herramientas de contenido
- Conservar asistentes sin sobrescritura, propuestas sin mutar originales y registro con Deshacer/Rehacer. Deshacer no borra archivos.
- Mantener recompensas/eventos como Resources; los campos nuevos son opcionales para conservar reglas y RNG de partidas anteriores.
- Probar authoring en rutas aisladas; nunca guardar copias de prueba sobre Resources de producción.

- Los editores especializados usan `tools/editor/editing.gd` para propuestas sin mutación y el historial del editor para aplicarlas. No aplicar borradores inválidos ni guardar automáticamente al cerrar.
- `route_nodes` es opcional: conservar el generador original cuando falte. Validar conectividad y reproducibilidad; el editor comparte la resolución de enemigos con el juego.
- Ejecutar `tests/editor_workflows.gd` al modificar mazos, decisiones o rutas personalizadas. Para integración con el historial nativo, usar una instancia nueva: `godot --headless --editor --path . -- --test-content-editors`; el comando prueba copias en memoria y cierra el editor.

## Multiplataforma y UI
- Conservar Scroll/Margin y nombres únicos en interfaz/expedición/ajustes. Sumar zonas seguras a los márgenes editados, sin acumularlas ni rehacer la UI por código.
- Guardar preferencias en un ConfigFile independiente de la partida; mantener ajustes como multiplicadores de cámara/efectos de la escena. Atajos solo en contextos válidos y fuera de edición de texto.
- Ejecutar `tests/platform_ui.gd` para cambios de plataforma. Las pruebas de paquetes requieren exportar antes y ejecutar `tests/package_smoke.gd` desde disco con `--main-pack`. No confundir el motor Linux con una prueba nativa Windows/Android.
- Mantener builds, SDK, plantillas, claves y credenciales fuera de Git. Usar Godot/plantillas 4.6.3, formatos S3TC/BPTC y ETC2/ASTC. Véase `EXPORTAR_PC_ANDROID.md`.
