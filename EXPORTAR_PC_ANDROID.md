# Exportar a PC y Android
1. Instala Godot 4.6.3 estándar y sus plantillas de exportación de la misma versión desde el editor.
2. Abre Proyecto → Exportar y crea un preset Windows Desktop. Selecciona una carpeta `build/` para la salida. Prueba el ejecutable en Windows.
3. Para Android, instala OpenJDK 17 y Android SDK siguiendo la documentación oficial correspondiente a Godot 4.6. Configura Java SDK y Android SDK en los ajustes del editor.
4. Crea un preset Android, identificador de paquete propio y exportación de depuración. Comprueba orientación horizontal, tacto, tamaños de texto y zonas seguras en un dispositivo real.
5. Para publicar, crea y protege la clave de firma fuera del repositorio. No añadas contraseñas ni claves a Git.

Referencia: https://docs.godotengine.org/en/stable/tutorials/export/index.html

Esta fase no incluye SDK, plantillas ni presets probados. No se ha generado un APK ni un ejecutable Windows. No se han medido FPS. El objetivo futuro es 30 FPS en Android modesto, 60 cuando sea posible. Quedan pendientes zonas seguras, perfiles de calidad, ajustes y validación de distintas densidades.
