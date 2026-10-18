# Crear personajes
En `data/content.json`, duplica la definición de Noa o Lira en `characters`. Usa un `id` único y cambia `name`, `health`, `attack`, `defense`, `energy`, `affinity` y `color` (hexadecimal RGB).

1. Duplica las cartas que quieras para el nuevo personaje, asigna IDs únicos y cambia `owner` a su nuevo ID.
2. En `deck`, escribe los IDs de sus cartas. Repetir un ID añade copias. El mazo solo admite cartas de ese propietario.
3. En `special`, referencia una de sus cartas especiales. Aparece con ★; inclúyela en `deck` si quieres robarla.
4. Configura `stress_limit`, `crisis.energy_loss` y `crisis.relief`. `passive.start_block` da escudo al empezar turno y `passive.stress_relief` reduce estrés después de evaluar la crisis.
5. Añade su ID a `team` para seleccionarlo por defecto (máximo tres); todos los personajes aparecen automáticamente en el menú y pueden incluirse o retirarse. Se requiere al menos uno.
6. Abre el juego y ejecuta las pruebas del README. La prueba de tres integrantes demuestra que no hace falta duplicar el combate.

Las estadísticas de combate y el color son funcionales. `affinity` identifica el elemento para contenido futuro; aún no aplica resistencias ni ventajas elementales. No existe selección de retratos ni progresión persistente todavía. Para asociar imagen o SpriteFrames propios, crea un perfil visual según `COMO_CAMBIAR_GRAFICOS.md`; Lira y Noa ya tienen ilustraciones provisionales distintas.

Consulta `documentation/PERSONAJES_Y_ESTRES.md` para el orden exacto de turnos y estados.
