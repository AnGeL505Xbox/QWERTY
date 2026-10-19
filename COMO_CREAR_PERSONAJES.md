# Crear personajes visualmente
1. Duplica `data/characters/noa.tres` desde Sistema de archivos. Asigna **Id** único y **Display Name** en el Inspector.
2. Ajusta **Health**, **Attack**, **Defense**, **Energy**, **Affinity** y **Color**. Affinity sigue siendo información para reglas elementales futuras.
3. Duplica las cartas que quieras para el nuevo personaje. Cambia sus IDs y **Owner** al nuevo ID. Regístralas en **Cards** de `data/catalog.tres`.
4. En **Deck** del personaje, reemplaza las cartas de Noa por las nuevas arrastrando sus `.tres`. **Special** debe apuntar a una carta suya. Solo Deck determina las cartas que se roban.
5. Ajusta las categorías **Estrés y crisis** y **Pasivas**: **Crisis Energy Loss**, **Crisis Relief**, **Passive Start Block**, **Passive Stress Relief**.
6. Arrastra un perfil de `visuals/profiles/` a **Visual Profile**. Puedes duplicar un perfil para cambiar textura, SpriteFrames o color sin afectar a otros.
7. Añade el nuevo recurso a **Characters** del catálogo. Para seleccionarlo por defecto, arrástralo también a **Team** (de uno a tres integrantes). Todos los registrados aparecen en el menú.
8. Guarda, valida y ejecuta F5. La prueba de tres integrantes demuestra que no hace falta duplicar el código de combate.

El orden de Team es el orden de los slots y del objetivo enemigo. Modifica `scenes/visuals/arena.tscn` → `AllySlots/Slot1…3` para moverlos en el escenario. La escena `scenes/visuals/actor.tscn` define la estructura visual compartida.

**Color** es el respaldo para un personaje sin perfil; si tiene Visual Profile, manda su **Tint**. No hay selección de retratos, resistencias elementales ni desbloqueos permanentes todavía. La expedición conserva vida, estrés, mazos y mejoras en su guardado local.

Consulta `EDICION_VISUAL.md` y `documentation/PERSONAJES_Y_ESTRES.md` para las reglas exactas.
