# Crear enemigos visualmente
1. Duplica `data/enemies/eco.tres` y asigna un **Id** nuevo y **Display Name** en el Inspector.
2. Cambia **Health** y despliega **Pattern**. Cada elemento es un `RpgIntentDefinition` con **Type** (`attack`, `guard`, `heal`) y **Amount** entero no negativo.
3. Ejemplo de un Vigía: vida 35, primera intención `guard` de 4 y segunda `attack` de 7. El patrón se repite en ese orden.
4. Arrastra un perfil visual a **Visual Profile**. Duplica `visuals/profiles/enemy.tres` si quieres otro gráfico o tinte. Sin perfil propio se utiliza el respaldo de la escena.
5. Añade el archivo a **Enemies** de `data/catalog.tres`. Guarda, valida y ejecuta F5: aparecerá en el menú automáticamente.

La intención mostrada es la acción que realizará al terminar tu turno. Los ataques anuncian al primer aliado vivo según el orden del equipo. La defensa reduce daño antes del escudo y el daño real añade estrés. La curación no supera la vida inicial y el escudo enemigo expira antes de su siguiente acción.

Para cambiar la posición del enemigo, mueve **EnemySlot** en `scenes/visuals/arena.tscn`. Para incluirlo en expediciones nuevas, arrástralo también a Encounters de `data/progression/expedition.tres`. El jefe tiene el campo Boss y puede usar una definición independiente como `data/progression/boss.tres`. Prueba nuevos patrones y su dificultad antes de distribuirlos.
