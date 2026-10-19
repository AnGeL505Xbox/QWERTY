# Instantáneas de compatibilidad

`phase6_combat.json` y `phase6_next_turn.json` se generaron en Godot 4.6.3 con el modelo y generador de rutas del commit **efd57d7** (fase 6), catálogo de ese commit y `data/progression/expedition.tres` anterior a la expansión.

Procedimiento: equipo Lira/Noa, semilla 42, entrar en `0_0`, finalizar un turno y sincronizar el equipo; guardar con Store versión 1. Finalizar otro turno sin jugar cartas, sincronizar y guardar la segunda instantánea. Cada archivo incluye la instantánea completa y su checksum; no contiene rutas personales ni claves.

`tests/expansion.gd` copia estos archivos a rutas temporales, carga el primero, comprueba su restauración exacta y compara su siguiente turno con el segundo. No regenerarlos con el código nuevo para hacer pasar pruebas: representan el comportamiento anterior que se debe conservar. El JSON histórico de contenido tampoco se actualiza al ampliar el catálogo.
