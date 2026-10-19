# Exportar a Windows y Android

El repositorio incluye `export_presets.cfg`: **Windows Desktop x86_64** y **Android arm64** horizontal con modo inmersivo. Usa Godot estándar **4.6.3**, con plantillas de la misma versión. Ambos formatos de importación de texturas, S3TC/BPTC y ETC2/ASTC, están habilitados en el proyecto.

## Preparación en Linux/nube

La máquina actual ya tiene Godot 4.6.3 y OpenJDK 21. Para reutilizar sus directorios:

```sh
cd /workspace/QWERTY
export XDG_DATA_HOME=/tmp/qwerty-godot/data
export XDG_CONFIG_HOME=/tmp/qwerty-godot/config
export XDG_CACHE_HOME=/tmp/qwerty-godot/cache
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export ANDROID_HOME=/tmp/qwerty-android-sdk
export ANDROID_USER_HOME=/tmp/qwerty-android-user
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
```

Ajusta JAVA_HOME a tu JDK si está instalado en otra ubicación. En una instalación nueva, el preparador requiere Python 3.11+, JDK y Godot ya instalados:

```sh
python3 tools/provision_exports.py --android --accept-sdk-licenses
```

El comando instala las plantillas verificando el SHA-512 oficial, command-line tools 19.0 con el checksum de su repositorio oficial, platform-tools, Build Tools 36.0.0 y plataforma Android 36. `--accept-sdk-licenses` acepta las licencias solicitadas por sdkmanager. Fija las rutas de SDK/JDK en los ajustes locales de Godot sin modificar el proyecto. Genera una clave **solo de depuración** fuera del repositorio; no sirve para publicar una versión de producción. El preparador se comprobó de nuevo sobre la instalación existente sin reinstalarla.

adb usa la carpeta real `~/.android` obtenida del usuario del sistema y no admite redirigirla con ANDROID_USER_HOME. En un sandbox puede ser necesario permitir crear esa carpeta; no cambies HOME. Esa carpeta ya se creó en esta máquina.

Los servicios de la API/portal de Godot respondieron 403 en esta máquina; las descargas directas oficiales desde github.com y dl.google.com sí funcionaron. No se desactivó la verificación TLS ni de checksums.

## Comprobar requisitos y exportar

```sh
godot --headless --path . --script tools/check_export_environment.gd
godot --headless --path . --script tools/check_export_environment.gd -- --android
mkdir -p build/windows build/android
godot --headless --path . --export-release 'Windows Desktop' build/windows/UmbralDeNacar.exe
godot --headless --path . --export-debug Android build/android/UmbralDeNacar.apk
```

El comprobador CLI consulta las variables SDK/JDK anteriores y presencia de archivos; no sustituye la validación del exportador. También puedes exportar desde Proyecto → Exportar. En una máquina distinta configura las rutas de SDK/JDK en los ajustes del editor.

Distribuye **EXE y PCK juntos** en Windows. En Android instala el APK de depuración en un dispositivo arm64 compatible: desde su administrador de archivos o mediante `adb install -r build/android/UmbralDeNacar.apk`. No se ha ejecutado ese paso en un dispositivo de esta máquina.

El identificador actual es `org.angel505.umbraldenacar`, versión 0.8.0/código 2. Cámbialo antes de tu distribución si corresponde. Para publicación Android configura tu clave de producción y versión de lanzamiento fuera de Git; los presets no incluyen credenciales. `build/`, keystores y archivos de credenciales están ignorados. No se ha publicado ningún binario en GitHub o tiendas.

## Paquetes de recursos para regresión

Sin ejecutar el binario de cada plataforma se puede comprobar su contenido con el motor Linux:

```sh
godot --headless --path . --export-pack 'Windows Desktop' build/windows/content.pck
godot --headless --path . --export-pack Android build/android/content.pck
mkdir -p /tmp/qwerty-package-runtime
godot --headless --path /tmp/qwerty-package-runtime --main-pack /workspace/QWERTY/build/windows/content.pck --script /workspace/QWERTY/tests/package_smoke.gd
godot --headless --path /tmp/qwerty-package-runtime --main-pack /workspace/QWERTY/build/android/content.pck --script /workspace/QWERTY/tests/package_smoke.gd
```

Cada paquete superó siete comprobaciones de arranque, combate, ajustes, expedición y exclusión de herramientas. Esto valida recursos y scripts en Linux, no la ejecución nativa de Windows/Android.

## Pruebas en dispositivos pendientes

Comprueba en Windows el ejecutable, cambio de tamaño, pantalla completa, teclado/foco, guardado y vuelta al menú. En Android comprueba tacto, desplazamiento, notch/zonas seguras, barras del sistema, Atrás, teclado virtual, suspensión/reanudación y guardado. Revisa textos y alcanza los botones inferiores en pantallas pequeñas.

Mide FPS y temperatura con cada perfil en tu dispositivo. No hay mediciones de rendimiento, sesión gráfica Windows, emulador ni teléfono conectado en esta fase. La configuración de las opciones está probada; los objetivos de 30 FPS en Android modesto y 60 cuando sea posible todavía requieren mediciones.

Referencia oficial: https://docs.godotengine.org/en/stable/tutorials/export/index.html

## Resultado de esta máquina

Se generaron `build/windows/UmbralDeNacar.exe` y su PCK (Windows x86_64) y `build/android/UmbralDeNacar.apk` (depuración arm64). Se verificaron firma APK v2/v3 y alineación; sus metadatos indican paquete `org.angel505.umbraldenacar`, versión 0.8.0, mínimo Android API 24 y destino API 36. El manifiesto incluye una actividad alias de lanzamiento y no solicita Internet. El PCK del ejecutable Windows también superó las siete comprobaciones de arranque. Esto no demuestra ejecución nativa en esos sistemas. Los binarios permanecen en `build/`, fuera de Git.

Comprobación comunicada por el usuario: la fase 6 funciona en Android y PC, con 60 FPS estables en su PC. Los binarios 0.8.0 incorporan contenido nuevo y necesitan repetir esa comprobación; no se extrapolan esas mediciones a esta versión.
