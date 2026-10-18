# Crear cartas desde el Inspector
## Cambiar una carta existente
Abre `data/cards/corte.tres` o selecciónala en el panel **Contenido**. Cambia **Cost**, **Description** y **Effects → 0 → Amount**. Guarda y ejecuta F5. **Illustration** admite una textura arrastrada desde Sistema de archivos.

## Duplicar una carta
1. Duplica `data/cards/corte.tres` desde Sistema de archivos y nómbrala `chispa.tres`.
2. En el Inspector usa **Id** `chispa`, **Display Name** `Chispa`, **Owner** `lira`, **Cost** `2`, **Target** `enemy`.
3. En **Effects**, edita el recurso `RpgEffectDefinition`: **Type** `damage`, **Amount** `10`. Actualiza la descripción.
4. Abre `data/catalog.tres`, amplía **Cards** y arrastra `chispa.tres` al elemento nuevo.
5. Abre `data/characters/lira.tres`, amplía **Deck** y arrastra el mismo archivo. Repetir el recurso añade copias al mazo.
6. Guarda y pulsa **Validar contenido**. El registro en Cards permite reconocerla; Deck determina que pueda robarse.

Los efectos incrustados se copian al duplicar el archivo. Si tú vinculas un efecto externo compartido entre cartas, sus cambios afectarán a ambas; usa **Hacer único** si quieres separarlos.

## Campos y efectos
**Owner** es el ID estable del personaje que paga el coste. **Target**: `enemy` para daño, `self` para el dueño, `ally` para un aliado vivo elegido (curación, escudo, calma o estado). **Exhaust** retira la carta después de jugarla; no se agota solo por descartarla al terminar turno.

Efectos disponibles: `damage`, `block`, `heal`, `draw`, `energy`, `calm`, `status`. La magnitud **Amount** es entera no negativa; para `status` es una duración positiva. En ese caso arrastra un `.tres` de `data/statuses/` al campo **Status**. `impulso.tres` muestra Resonancia de dos rondas y `refugio.tres` combina dos efectos compatibles con el mismo destino.

El daño suma el ataque efectivo del dueño. Una habilidad especial es una carta referenciada por **Special** del personaje y marcada con ★; añade esa carta a Deck para robarla. Rarezas y mejoras todavía no están implementadas.

## Nuevas reglas
Para un tipo de efecto totalmente nuevo, crea su módulo en `core/effects/`, regístralo en `registry.gd`, añade la opción al enum de `core/data/resources/effect_definition.gd` y añade pruebas de comportamiento. No hace falta modificar el bucle de Battle.play. La edición visual configura las reglas disponibles; no genera código de combate.

El diseño visual se modifica en `scenes/ui/card.tscn`. Selecciona su raíz y cambia **Preview Card** para ver otra carta en el editor. Consulta `EDICION_VISUAL.md`.
