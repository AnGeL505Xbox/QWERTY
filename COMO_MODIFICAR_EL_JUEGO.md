# Modificar el juego
Empieza por `EDICION_VISUAL.md`: es el recorrido para editar sin escribir GDScript. El panel **Contenido** abre recursos, escenas y validación.

- **Cartas:** `data/cards/*.tres` → Cost, Effects, Description, Illustration.
- **Personajes:** `data/characters/*.tres` → estadísticas, energía, estrés, Deck, Special y Visual Profile.
- **Enemigos:** `data/enemies/*.tres` → vida y Pattern.
- **Roguelike:** `data/progression/expedition.tres` y `scenes/exploration/`; consulta `documentation/ROGUELIKE_Y_GUARDADO.md`.
- **Balance y registros:** `data/catalog.tres` → Hand Size, Cards, Characters, Enemies, Statuses y Team.
- **Escenario y posiciones:** `scenes/visuals/arena.tscn`.
- **Interfaz y cartas:** `scenes/ui/interface.tscn`, `card.tscn` y `theme.tres`.

Guarda escenas y recursos antes de ejecutar F5. Los contenedores repetidos se llenan durante el juego desde plantillas; los textos de estadísticas cambian con el estado de combate. Las guías de cartas, personajes, enemigos y gráficos muestran ejemplos concretos.

Las pruebas numéricas incluyen el balance original como regresión. Si lo modificas deliberadamente, revisa esas expectativas; un fallo no significa necesariamente que tu nuevo balance sea incorrecto. Prueba también una partida real.

Haz una rama y commits pequeños. No cambies IDs existentes sin revisar referencias y futuras partidas guardadas. `data/content.json` se conserva como referencia histórica y ya no es la fuente activa.
