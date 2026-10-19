# Fase 6: base multiplataforma y UI

## Cambios disponibles

- Ventanas de mazos, eventos, rutas, creación y vista previa con tamaño limitado al área disponible, desplazamiento y botones de confirmación fuera del contenido desplazable. El foco acompaña el desplazamiento.
- Menú, combate, expedición y ajustes dentro de ScrollContainer. Cabeceras largas y estadísticas se ajustan al ancho; las acciones usan HFlowContainer. Los botones de acción conservan un mínimo de 48 unidades lógicas.
- Zonas seguras: se convierten los márgenes físicos de pantalla a las unidades del viewport y se suman a los márgenes editados, sin acumularlos al redimensionar. El viewport amplía su relación de aspecto y el juego sigue en horizontal.
- Teclado y tacto usan las mismas señales y reglas de combate. Los ajustes ocultan los controles de juego mientras están abiertos.
- Preferencias locales separadas de la expedición: calidad 3D, límite de FPS, movimiento de cámara, efectos y pantalla completa de PC. Los datos inválidos recuperan predeterminados; un archivo malformado se conserva hasta aplicar otros ajustes.
- Guardado de expedición al pausar la aplicación, volver al menú y cerrar la ventana. Se conserva el formato de guardado anterior.

## Controles

| Acción | PC | Android |
|---|---|---|
| Navegar y activar botones | Tab / Mayús+Tab, Enter | Tocar |
| Elegir carta | 1–9; Tab; ratón | Tocar carta |
| Confirmar objetivo | Enter sobre objetivo enfocado; ratón | Tocar objetivo |
| Terminar turno | E o botón | Botón |
| Cancelar selección / volver al menú | Esc | Atrás o botones |
| Ajustes | F10 o botón | Botón |
| Pantalla completa | F11 o ajustes | Modo inmersivo del preset |
| Desplazar listas | Rueda, barras o foco | Deslizar |

Las repeticiones del teclado y combinaciones Ctrl/Alt/Meta no juegan cartas ni terminan turnos. Los atajos de combate no se ejecutan mientras se editan textos o están abiertos los ajustes. Esc cancela primero una carta seleccionada; otra pulsación vuelve al menú. Las cartas siguen necesitando confirmar objetivo.

## Ajustes y perfiles

`Ajustes → Aplicar y guardar` escribe `user://preferences.cfg`; Volver sin aplicar descarta el borrador. El perfil predeterminado es Ahorro/30 en Android y Equilibrado/60 en PC.

| Calidad | Resolución 3D relativa | MSAA |
|---|---|---|
| Ahorro | 65 % | Desactivado |
| Equilibrado | 85 % | Desactivado |
| Alto | 100 % | 2× |

El límite 30/60 es independiente del perfil. La interfaz conserva su resolución. El rendimiento real y el resultado del escalado dependen del controlador y del dispositivo; no hay mediciones de FPS de esta fase.

Reducir movimiento afecta a la cámara; los personajes siguen animados. Los interruptores de cámara/efectos actúan como multiplicadores de `Arena.motion_enabled` y `Feedback.enabled`: no habilitan algo desactivado en la escena.

## Dónde modificar la UI

- `scenes/ui/interface.tscn`: menú y combate.
- `scenes/exploration/run_ui.tscn`: mapa, decisiones y recompensas.
- `scenes/settings/settings.tscn`: pantalla de ajustes, etiquetas y controles.
- `scenes/ui/theme.tres`, `action_button.tscn`, `member_row.tscn` y `card.tscn`: apariencia y plantillas.
- `core/platform/safe_area.gd`: conversión de zonas seguras; `preferences.gd`: normalización, persistencia y perfiles.
- `tools/editor/dialog_layout.gd`: límite de las ventanas del editor y contenedor desplazable.

**Migración de rutas de nodos:** en interfaz y expedición se añadió un `Scroll` por encima de `Margin`. Las rutas anteriores `Margin/...` son ahora `Scroll/Margin/...`. Los nombres únicos `%...`, señales y Resources se conservan. Si tienes scripts o escenas locales con rutas literales antiguas, actualízalos. No cambió `Margin/Content` dentro de las cartas.

Los márgenes y estilos permanecen editables en las escenas; los scripts no reconstruyen esos controles. Los borradores de los editores siguen admitiendo Deshacer/Rehacer.

## Validación y límites

Se comprobaron el menú a 640×360 con desplazamiento y foco, la conversión matemática de zonas seguras, ajustes guardados/recargados, recuperación de archivo malformado, atajos, bloqueo de entradas durante ajustes, guardado al pausar y respeto de opciones visuales editadas. La prueba de configuración malformada muestra un diagnóstico de ConfigFile esperado; sus comprobaciones deben terminar sin fallos.

La prueba nativa del plugin comprueba que las ventanas caben en el editor, tienen desplazamiento y conservan el historial. Las pruebas sin ventana no sustituyen la revisión gráfica con ratón o tacto físico.

Consulta `EXPORTAR_PC_ANDROID.md` para generar binarios y comprobarlos en dispositivos. La base de fase 6 está implementada; su aceptación en Windows/Android reales, notch/barra de navegación, suspensión/reanudación, teclado virtual, legibilidad y rendimiento sigue pendiente. La fase 8 no se ha empezado.

Se generaron un ejecutable Windows x86_64 con su PCK y un APK Android arm64 de depuración, cuya firma y alineación se verificaron. La batería tiene 458 comprobaciones sin fallos, más las siete comprobaciones por paquete de recursos. No se han ejecutado esos binarios en Windows o Android.
