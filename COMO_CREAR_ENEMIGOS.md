# Crear enemigos
En `data/content.json`, duplica una entrada de `enemies`, asigna un ID único y configura `name`, `health` y `pattern`. Aparecerá automáticamente en el menú. Ejemplo:

```json
{"id":"vigia","name":"Vigía","health":35,"pattern":[{"type":"guard","amount":4},{"type":"attack","amount":7}]}
```

Las acciones disponibles son `attack`, `guard` y `heal`. El patrón se repite desde su primera entrada. La intención mostrada es exactamente la acción que ejecutará al terminar tu turno. La curación no supera la vida inicial; la guardia absorbe daño y expira antes de la siguiente acción enemiga. Magnitudes enteras no negativas.

Los tres enemigos reutilizan el sprite provisional; arte por enemigo y selección de encuentros roguelike quedan pendientes. Prueba nuevos patrones y su dificultad antes de publicarlos.
