# Modificar el juego
Haz una rama antes de cambiar contenido. Abre `data/content.json`: `characters[].energy` cambia la energía de cada personaje y `balance.hand_size` el robo compartido. `characters[].deck` define sus cartas. `team` define el equipo inicial; su orden determina a quién atacará primero el enemigo.

Las pruebas usan el balance inicial como ejemplo de regresión: si lo cambias deliberadamente, revisa sus expectativas. Ejecuta también el juego para comprobar si el combate sigue siendo justo.

Consulta las guías de cartas, personajes, enemigos y gráficos. Haz commits pequeños. No cambies IDs existentes sin considerar futuras partidas guardadas.
