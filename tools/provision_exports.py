#!/usr/bin/env python3
"""Prepara exportaciones en Linux sin tocar fuentes, credenciales de publicación ni HOME."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import urllib.request
import zipfile

VERSION = "4.6.3"
TEMPLATE_SHA512 = "da606b61c10157844f8300172df374472665f95015495cb1a7cd132c40ede404faa96cc1016a4b9662db9909ddea69632c4948b2cd11163438dad4808881fb68"
TOOLS_SHA1 = "5fdcc763663eefb86a5b8879697aa6088b041e70"  # Repositorio oficial Android: cmdline-tools;19.0.


def download(url, output, algorithm, expected):
    if output.exists():
        with output.open("rb") as existing:
            if hashlib.file_digest(existing, algorithm).hexdigest() == expected:
                return
    digest = hashlib.new(algorithm)
    with urllib.request.urlopen(url, timeout=90) as source, output.open("wb") as target:
        while chunk := source.read(4 * 1024 * 1024):
            target.write(chunk)
            digest.update(chunk)
    if digest.hexdigest() != expected:
        output.unlink()
        raise RuntimeError("Checksum incorrecto; descarga eliminada: " + output.name)
    print("Verificado:", output.name, flush=True)


def configure_editor(config_root, sdk, java):
    file = config_root / "godot/editor_settings-4.6.tres"
    file.parent.mkdir(parents=True, exist_ok=True)
    text = file.read_text() if file.exists() else '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
    values = {"export/android/android_sdk_path": str(sdk), "export/android/java_sdk_path": str(java), "export/android/debug_keystore": str(sdk / "debug.keystore")}
    for key, value in values.items():
        line = key + " = " + json.dumps(value)
        pattern = r"^" + re.escape(key) + r" = .*$"
        text = re.sub(pattern, lambda _: line, text, flags=re.M) if re.search(pattern, text, re.M) else text + "\n" + line + "\n"
    file.write_text(text)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--android", action="store_true")
    parser.add_argument("--accept-sdk-licenses", action="store_true", help="Aceptar las licencias solicitadas por sdkmanager durante la instalación.")
    args = parser.parse_args()
    for name in ["XDG_DATA_HOME", "XDG_CONFIG_HOME"]:
        if not os.environ.get(name):
            raise SystemExit("Declara " + name + " con una carpeta escribible (ver EXPORTAR_PC_ANDROID.md).")
    engine = shutil.which("godot")
    if engine is None or not subprocess.check_output([engine, "--version"], text=True).strip().startswith(VERSION + "."):
        raise SystemExit("Se requiere Godot estándar " + VERSION + ".")
    cache = Path(os.environ.get("XDG_CACHE_HOME", "/tmp/qwerty-godot/cache")) / "export-downloads"
    cache.mkdir(parents=True, exist_ok=True)
    templates = Path(os.environ["XDG_DATA_HOME"]) / "godot/export_templates/4.6.3.stable"
    selected = {"windows_release_x86_64.exe", "windows_debug_x86_64.exe", "android_debug.apk", "android_release.apk"}
    if not all((templates / name).exists() for name in selected):
        name = f"Godot_v{VERSION}-stable_export_templates.tpz"
        archive = cache / name
        download(f"https://github.com/godotengine/godot/releases/download/{VERSION}-stable/{name}", archive, "sha512", TEMPLATE_SHA512)
        templates.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(archive) as package:
            for entry in package.infolist():
                if Path(entry.filename).name in selected:
                    with package.open(entry) as source, (templates / Path(entry.filename).name).open("wb") as target:
                        shutil.copyfileobj(source, target)
        if not all((templates / name).exists() for name in selected):
            raise RuntimeError("El archivo oficial no contiene todas las plantillas esperadas.")
    print("Plantillas Godot", VERSION, "disponibles", flush=True)
    if not args.android:
        return
    executable = shutil.which("java")
    if executable is None:
        raise SystemExit("Instala un JDK compatible; esta preparación se verificó con OpenJDK 21.")
    java = Path(os.environ.get("JAVA_HOME") or Path(executable).resolve().parent.parent)
    sdk = Path(os.environ.get("ANDROID_HOME", "/tmp/qwerty-android-sdk"))
    sdk.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.update(JAVA_HOME=str(java), ANDROID_HOME=str(sdk), ANDROID_USER_HOME=os.environ.get("ANDROID_USER_HOME", "/tmp/qwerty-android-user"))
    manager = sdk / "cmdline-tools/19.0/bin/sdkmanager"
    if not manager.exists():
        archive = cache / "commandlinetools-linux-13114758_latest.zip"
        download("https://dl.google.com/android/repository/" + archive.name, archive, "sha1", TOOLS_SHA1)
        with tempfile.TemporaryDirectory(dir=cache) as staging:
            with zipfile.ZipFile(archive) as package:
                for entry in package.infolist():
                    if not (Path(staging) / entry.filename).resolve().is_relative_to(Path(staging).resolve()):
                        raise RuntimeError("Ruta inválida en archivo SDK.")
                package.extractall(staging)
            manager.parent.parent.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(Path(staging) / "cmdline-tools"), manager.parent.parent)
        for tool in manager.parent.iterdir():
            tool.chmod(0o755)
    expected = [sdk / "platform-tools/adb", sdk / "build-tools/36.0.0/apksigner", sdk / "platforms/android-36/android.jar"]
    if not all(path.exists() for path in expected):
        if not args.accept_sdk_licenses:
            raise SystemExit("Faltan paquetes. Repite con --accept-sdk-licenses para instalar y aceptar sus licencias.")
        subprocess.run([str(manager), "--sdk_root=" + str(sdk), "platform-tools", "build-tools;36.0.0", "platforms;android-36"], input="y\n" * 100, text=True, env=env, check=True)
    if not (sdk / "debug.keystore").exists():
        subprocess.run([str(java / "bin/keytool"), "-genkeypair", "-keystore", str(sdk / "debug.keystore"), "-storepass", "android", "-keypass", "android", "-alias", "androiddebugkey", "-dname", "CN=Android Debug,O=Android,C=US", "-keyalg", "RSA", "-keysize", "2048", "-validity", "10000"], check=True)
    configure_editor(Path(os.environ["XDG_CONFIG_HOME"]), sdk, java)
    # adb utiliza getpwuid(), sin respetar ANDROID_USER_HOME. Necesita esta carpeta real.
    (Path.home() / ".android").mkdir(exist_ok=True)
    print("SDK Android y ajustes locales listos. Clave de depuración fuera del repositorio.", flush=True)


if __name__ == "__main__":
    main()
