# Cambiar gráficos
`visuals/traveler.svg` es una silueta original provisional utilizada por ambos combatientes con tintes distintos. Sustituye la textura cargada en `visuals/arena.gd` por tu SVG o PNG importado. Ajusta `pixel_size` para conservar tamaño.

`_character` construye sprites billboard dentro del mundo 3D. `animate` reacciona a señales y el tween de reposo mueve al personaje. Puedes sustituirlos progresivamente por AnimatedSprite3D y AnimationPlayer, conservando la separación con `Battle`. No hay aún nueve animaciones ni arte anime definitivo.

El escenario se construye en `_ready` de `arena.gd`; modifica geometría, colores o cámara allí. Evita luces y transparencias costosas en móvil.
