# Crear cartas
En `data/content.json`, duplica una entrada de `cards`, asigna un `id` único y añade ese ID a `starter_deck` para jugarla.

Ejemplo: `{"id":"chispa","name":"Chispa","cost":2,"target":"enemy","exhaust":false,"description":"Inflige 10 de daño.","effects":[{"type":"damage","amount":10}]}`.

`cost` controla energía y `amount` la magnitud entera no negativa. `target` es `enemy` (daño) o `self` (los demás efectos). `exhaust: true` retira la carta del combate después de jugarla; si solo la descartas al terminar turno, no se agota.

Efectos: `damage`, `block`, `heal`, `draw` (robar) y `energy` (ganar energía durante este turno). Una carta puede combinar efectos del mismo destino, ejecutados en orden. La descripción se edita manualmente y debe coincidir con las reglas. Ejemplos reales: `lectura`, `reserva` y `refugio`.

Para un nuevo efecto, crea un módulo en `core/effects/` con `static func apply(battle, amount: int) -> void`. Regístralo en `registry.gd` junto con su destino y añade pruebas de comportamiento en `tests/run.gd`. No necesitas editar el bucle de `Battle.play`.

Las mejoras, rarezas, estados y editor visual quedan pendientes. Para comprobar cambios, ejecuta los comandos del README; las expectativas numéricas de pruebas deben revisarse si cambias el balance deliberadamente.
