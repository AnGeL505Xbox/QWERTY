# Crear enemigos
En `data/content.json`, `enemies[0]` define al enemigo activo: `health` es su vida y `damage` su ataque fijo por turno. Cambia también el nombre visible en `scenes/main.gd` al sustituirlo.

Otros enemigos pueden prepararse como datos con IDs distintos, pero selección de encuentros y patrones de IA todavía no están implementados. Añadirlos al JSON no los activa automáticamente.
