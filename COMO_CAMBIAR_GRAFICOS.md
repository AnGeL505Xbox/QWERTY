# Cambiar gráficos y animaciones
## Imágenes y spritesheets
1. Importa un PNG o SVG propio en `visuals/characters/`.
2. Abre el **Visual Profile** de un personaje o enemigo (por ejemplo `visuals/profiles/noa.tres`). Arrastra la imagen a **Texture**. Ajusta **Pixel Size** y **Tint**.
3. Para un perfil independiente, duplica ese `.tres` y arrástralo al campo **Visual Profile** de `data/characters/*.tres` o `data/enemies/*.tres`.
4. Para spritesheets, crea **SpriteFrames** en **Frames**, guarda el recurso y distribuye sus fotogramas con el editor nativo de Godot.

Los clips canónicos son `idle`, `enter`, `attack`, `defend`, `hurt`, `special`, `crisis`, `victory`, `defeat`. Si tus clips usan otros nombres, configura **Animation Names**, por ejemplo `attack: golpe`. **Durations** controla el tiempo del movimiento procedural. La lógica de combate no espera a los clips.

Falta de un clip usa `idle` o la primera animación con fotogramas. Sin fotogramas se utiliza Texture o el SVG original de respaldo. Para poses finales, los clips pueden dejarse sin bucle. Los gráficos actuales siguen siendo provisionales.

## Personaje visual en el editor
Abre `scenes/visuals/actor.tscn` o el botón **Personaje visual** del panel Contenido. El Profile de la raíz tiene vista previa en el editor. Cambia la escala/posición en **Pivot/VisualOffset** para un ajuste permanente; Pivot está reservado a la animación y se reinicia al actuar. **NameLabel** y **TargetMarker** se pueden recolocar y modificar.

Para una modificación local de un slot, abre `arena.tscn` y habilita **Hijos editables** de su instancia Actor. Los campos de imagen, tinte, SpriteFrames y tamaño por píxel se toman del perfil del combatiente al empezar una partida; edítalos en ese recurso para que sean efectivos en juego.

## Escenario y cámara
Abre `scenes/visuals/arena.tscn` en 3D: Stage contiene suelo, columnas y cristales editables. Puedes moverlos, duplicarlos y cambiar materiales. Camera3D, Sun y WorldEnvironment son nodos reales; no se regeneran en `_ready`.

Mueve **AllySlots/Slot1…3** o **EnemySlot** para cambiar las posiciones. La raíz Arena expone **Motion Enabled** y **Motion Amplitude**; desactiva la deriva para comprobar encuadres fijos. El nodo Feedback expone **Enabled** para desactivar números y anillos. Los tres slots reutilizan los actores y reinician sus animaciones en cada combate.

El código `visuals/effects/feedback.gd` todavía define duración y geometría de efectos transitorios, con límite de 24 nodos (12 parejas de texto/anillo). No hay aún un editor de partículas ni menú de ajustes persistentes. El escenario utiliza materiales simples, sin sombras dinámicas.

## Interfaz
`scenes/ui/interface.tscn` define menú y HUD; `scenes/ui/card.tscn` el diseño de cartas; `theme.tres` los estilos. Arrastra una textura a **Illustration** del `.tres` de carta para verla en el juego. En la plantilla de carta, **Preview Card** permite previsualizar distintos contenidos en el editor.

Consulta `EDICION_VISUAL.md` para los Containers, nodos dinámicos y validación. Sigue pendiente revisar la composición con un renderizador gráfico y probar Android; no se han medido FPS.
