# Crear cartas
En `data/content.json`, duplica una entrada de `cards`, asigna un `id` único y añade ese ID al `deck` de su propietario en `characters` para jugarla.

Ejemplo: `{"id":"chispa","name":"Chispa","cost":2,"owner":"lira","target":"enemy","exhaust":false,"description":"Inflige 10 de daño.","effects":[{"type":"damage","amount":10}]}`.

`cost` controla energía y `amount` la magnitud entera no negativa. `owner` debe ser un ID de personaje. `target` es `enemy` (daño), `self` (dueño) o `ally` (aliado vivo elegido, para curación, escudo, calma o estados). El coste siempre lo paga el dueño. `exhaust: true` retira la carta del combate después de jugarla; si solo la descartas al terminar turno, no se agota.

Efectos: `calm` (reduce estrés), `status` (estado temporal), `damage`, `block`, `heal`, `draw` (robar) y `energy` (ganar energía durante este turno). Una carta puede combinar efectos del mismo destino, ejecutados en orden. La descripción se edita manualmente y debe coincidir con las reglas. Ejemplos reales: `lectura`, `reserva` y `refugio`.

Para un nuevo efecto, crea un módulo en `core/effects/` con `static func apply(battle, amount: int) -> void`. Regístralo en `registry.gd` junto con su destino y añade pruebas de comportamiento en `tests/run.gd`. No necesitas editar el bucle de `Battle.play`.

Las mejoras, rarezas y editor visual quedan pendientes. Para comprobar cambios, ejecuta los comandos del README; las expectativas numéricas de pruebas deben revisarse si cambias el balance deliberadamente.

Ejemplo de estado: `{"type":"status","status":"strength","amount":2}` aplica Resonancia durante dos rondas. `amount` es duración entera positiva; la magnitud se define en `statuses.strength.attack`. La carta `impulso` muestra un ejemplo completo. El daño suma `attack` efectivo del propietario al `amount` de la carta.

Una habilidad especial es una carta normal referenciada por `characters[].special` y marcada con ★. No tiene un segundo sistema de costes ni botón oculto; `destello` y `aurora` se agotan tras usarse.
