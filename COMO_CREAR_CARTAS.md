# Crear cartas
En `data/content.json`, duplica una entrada de `cards`, asigna un `id` único y añade ese ID a `starter_deck` para jugarla.

Ejemplo: `{"id":"chispa","name":"Chispa","cost":2,"description":"Inflige 10 de daño.","effects":[{"type":"damage","amount":10}]}`.

`cost` controla energía y `amount` la magnitud. Efectos disponibles: `damage` al enemigo, `block` y `heal` al jugador. Una carta puede combinar varios efectos, ejecutados en orden. La descripción se edita manualmente y debe coincidir con las reglas.

Para un efecto nuevo, añade su operación a `Battle.play`, inclúyelo en la validación del catálogo y añade una prueba de comportamiento. En la próxima fase se extraerán resolutores independientes. Rarezas, mejoras, agotamiento y editor visual quedan pendientes.
