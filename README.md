# Primer

*Última modificación: 20 de octubre de 2026, 20:09 (CST)*

Visor mínimo de los canales deportivos de Prime Video (hoy NBA League Pass; MLB.TV más adelante): abre el sitio oficial en una ventana sin bordes, con uno o dos paneles, para ver dos partidos a la vez en una ventana 32:9 con el audio del panel sin foco silenciado.

> **Estado:** la versión de macOS está construida y casi toda validada por su autor. Falta la validación final de la sesión al reabrir y del uso completo con dos paneles. El plan y su avance están en `openspec/changes/add-macos-viewer/`.

Primer **no es un producto de Amazon, Prime Video, la NBA ni la MLB**. Consulta `NOTICE.md`.

## Qué hace

- **Sin bordes:** ventana arrastrable, con proporción fija: 16:9 con un panel y 32:9 con dos. Así el video no deja bandas negras.
- **Paneles:** Prime Video no trae vista múltiple, así que Primer ofrece hasta dos paneles independientes, pegados, para ver dos partidos a la vez. Los dos comparten la sesión.
- **Audio por foco:** con dos paneles solo suena el que tiene el foco; el otro queda silenciado, aunque su reproductor intente reactivar el sonido. Un silencio puesto a mano desde el reproductor se respeta.
- **El clic que da el foco no pausa:** un clic en el panel sin foco solo le pasa el foco y el audio, y no llega a la página.
- **Pantalla completa:** Primer no la toca. El reproductor de Prime Video llena por sí mismo la ventana o el panel, y su botón de pantalla completa usa la del sistema (Esc regresa).

## Requisitos

- **macOS con Apple Silicon.** Probado en macOS 26.7.1 con un Mac `arm64`; no se ha probado en otras versiones ni en Intel.
- **Swift.** Basta con las Herramientas de línea de comandos (`xcode-select --install`); no hace falta Xcode completo. Probado con Swift 6.4.
- **Una suscripción propia y válida** a un canal deportivo de Prime Video (hoy NBA League Pass). Primer no lee, guarda ni registra contraseñas.
- **Safari instalado.** Primer se identifica con el sufijo de Safari (`Version/27.0 Safari/605.1.15`, fijo en `macos/Primer.swift`) porque Prime Video rechazó la identificación predeterminada del motor. Si Prime Video deja de reproducir tras actualizar Safari, ese número es lo primero que hay que revisar.

## Compilar

```bash
cd macos
./build.sh           # compila con swiftc y firma de forma local
./build.sh --open    # además abre la aplicación
```

El paquete queda en `macos/Primer.app`. Su ejecutable y su firma se generan al compilar y no se versionan.

## Usar

Abre `macos/Primer.app` e inicia sesión en Prime Video; la sesión se conserva entre aperturas. Para otra instancia independiente, con la misma sesión:

```bash
open -n macos/Primer.app
```

| Atajo | Acción |
|---|---|
| ⌘1 · ⌘2 | Uno o dos paneles |
| ⌘\` | Pasar el foco y el audio al otro panel |
| ⌘L | Abrir una dirección en el panel con foco |
| ⌘R | Recargar el panel con foco |
| ⌘H | Inicio de Prime Video en el panel con foco |
| ⌘F | Rellenar y centrar: la ventana más grande que cabe en la pantalla, con su proporción |
| ⌘T | Siempre encima |
| ⌘W · ⌘Q | Cerrar · Salir |
| ⌥ + arrastrar | Mover la ventana desde cualquier punto (también se arrastra desde el borde superior) |

Con el panel sin foco, el clic que da el foco no pausa su video. Con el foco puesto, un clic en el video sí lo pausa, como hace Prime Video.

## Autoprueba

```bash
macos/Primer.app/Contents/MacOS/Primer --selftest
```

Comprueba por sí misma la ventana, los paneles, el audio por foco, los atajos y el diagnóstico con páginas locales de `shared/fixtures/`. **No usa red ni cuenta, no toca tu sesión y no abre Prime Video**: imprime una línea por comprobación y termina con código 0 solo si todas pasaron. No sustituye la prueba con un partido real. Con `PRIMER_FIXTURES=<carpeta>` se usan otras páginas de prueba.

## Diagnóstico

```bash
open -n macos/Primer.app --args --debug
```

Escribe `debug.log` junto a la aplicación y habilita el inspector web. Está apagado por omisión y no debe versionarse. Registra los eventos de audio (foco, silenciado y reactivaciones del reproductor) y de cada panel (tamaño, carga y descarga); de una dirección solo guarda servidor y ruta, nunca contraseñas, códigos ni el contenido de los campos.

## Estructura

```text
macos/     Swift sobre WKWebView: Primer.swift, build.sh y el paquete Primer.app
shared/    páginas locales de prueba de la autoprueba (shared/fixtures/)
openspec/  especificaciones y cambios: el plan de trabajo
```

## Cómo se trabaja

Este proyecto se desarrolla con especificaciones (OpenSpec) y con una persona que valida lo que solo una persona puede juzgar, como si el partido reproduce o cómo se ve. Para colaborar lee `AGENTS.md`.

## Licencia

GPLv3. Consulta `LICENSE`. Las marcas son de sus dueños (`NOTICE.md`).
