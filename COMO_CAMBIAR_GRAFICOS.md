# Cambiar gráficos y animaciones
## Cambiar una imagen sin tocar el combate
1. Importa tu PNG o SVG dentro de `visuals/characters/` (mantén recursos originales o con licencia).
2. Abre `visuals/profiles/lira.tres` o `noa.tres` en el Inspector de Godot y arrastra tu imagen a **Texture**. Ajusta **Pixel Size** para el tamaño y **Tint** para el color.
3. Para un nuevo personaje, duplica un perfil `.tres` y asocia su ID con la ruta en `visuals/profiles/catalog.json`.
4. Los enemigos usan `enemy.tres` por defecto. Puedes añadir una entrada con su ID (`eco`, `custodio`, `susurro`) al catálogo visual para darles un perfil propio.

Los perfiles conocidos toman el color de **Tint**; `characters[].color` del catálogo de combate es el respaldo para personajes sin perfil. No se modifican estadísticas al cambiar gráficos. El sprite anterior `visuals/traveler.svg` se conserva como Lira y recurso de respaldo. Noa y el enemigo tienen nuevos SVG provisionales originales.

## Usar spritesheets y animaciones nativas
En el perfil, crea un recurso **SpriteFrames** en **Frames**. Guarda ese recurso en `visuals/animations/` para reutilizarlo. Añade sus fotogramas desde tu spritesheet en el editor de SpriteFrames de Godot.

Los nombres canónicos son `idle`, `enter`, `attack`, `defend`, `hurt`, `special`, `crisis`, `victory` y `defeat`. Si tus clips tienen otros nombres, configura **Animation Names**, por ejemplo `attack: golpe`. Ajusta **Durations** (segundos) para que el movimiento procedural dure lo mismo que tus clips. El controlador no espera la duración del SpriteFrames para ejecutar reglas.

Si falta un clip, usa `idle` o la primera animación con fotogramas. Sin fotogramas, usa **Texture**, y si falta esta, el SVG de respaldo. El movimiento procedural continúa. Los clips finales pueden dejarse sin bucle para conservar su último fotograma.

## Movimiento y efectos
- `visuals/animations/actor.gd`: controlador reutilizable de nueve estados, cola limitada y estados finales protegidos.
- `visuals/effects/feedback.gd`: números flotantes y anillos de impacto/energía; colores y duración. Límite de 24 nodos transitorios (hasta 12 parejas texto/anillo).
- `visuals/arena.gd`: escenario, perfiles, cámara, resaltado y traducción de eventos a efectos.

Los objetivos válidos se marcan con un anillo dorado al seleccionar una carta. La defensa, daño, curación, estrés y estados muestran sus cambios reales; una curación limitada a 2 PV muestra +2, no la magnitud base de la carta. Especiales y crisis tienen un aviso adicional.

Puedes desactivar `arena.motion_enabled` para detener la deriva de cámara, o `arena.feedback.enabled` para desactivar los efectos transitorios. Son opciones de código locales; todavía no existe un menú de ajustes ni se guardan preferencias.

## Escenario 2.5D
`_ready` de `arena.gd` crea suelo, columnas y cristales a distintas profundidades, una cámara de perspectiva y luz ambiental. La deriva suave de cámara produce paralaje. Los personajes son AnimatedSprite3D orientados hacia cámara. El escenario usa materiales sencillos, sin sombras dinámicas ni partículas.

Para ampliar el escenario, modifica `_box` o añade una escena 3D bajo Arena. Conserva el área central de combate libre para que las cartas y el HUD sigan siendo legibles. Las ilustraciones y animaciones actuales son provisionales; no equivalen a arte anime final. No se ha revisado visualmente esta entrega con un renderizador gráfico ni probado el rendimiento Android.

Ejecuta las pruebas del README tras sustituir recursos y verifica siempre el resultado visual en Godot.
