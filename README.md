# Primer

*Última modificación: 20 de octubre de 2026, 23:14 (CST)*

Visor mínimo de los canales deportivos de Prime Video (hoy NBA League Pass; MLB.TV más adelante): abre el sitio oficial en una ventana sin bordes, con uno, dos o tres paneles, para ver varios partidos a la vez (dos en una ventana 32:9) con el audio del panel sin foco silenciado.

> **Estado:** la versión de macOS está construida y validada por su autor: ventana, paneles, audio por foco, sesión y uso completo con dos paneles; el tercer panel y las disposiciones están implementados y pasan la autoprueba, pendientes de validación con Prime Video. El plan, sus decisiones y el registro de lo que se validó están archivados en `openspec/changes/archive/2026-10-20-add-macos-viewer/`.

Primer **no es un producto de Amazon, Prime Video, la NBA ni la MLB**. Consulta `NOTICE.md`.

## Qué hace

- **Sin bordes:** ventana arrastrable, con proporción fija: 16:9 con un panel, 32:9 con dos y 48:9 con tres (en horizontal); 16:18 y 16:27 en vertical. Con un solo panel se puede cambiar a 1.85:1, 2.35:1, 2.39:1 o 2.40:1 (cine) para que las películas panorámicas no dejen bandas negras.
- **Paneles:** Prime Video no trae vista múltiple, así que Primer ofrece hasta tres paneles independientes, pegados, para ver varios partidos a la vez, uno junto al otro (horizontal, la disposición al abrir) o uno sobre otro (vertical). Todos comparten la sesión, y la disposición no se recuerda entre aperturas.
- **Audio por foco:** con dos o tres paneles solo suena el que tiene el foco; los demás quedan silenciados, aunque su reproductor intente reactivar el sonido. Un silencio puesto a mano desde el reproductor se respeta.
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

Para regenerar el ícono a partir de `shared/assets/icon.png`:

```bash
swiftc shared/scripts/make-icon.swift -o /tmp/make-icon
/tmp/make-icon shared/assets/icon.png macos/Primer.app/Contents/Resources/app.icns
```

## Usar

Abre `macos/Primer.app` e inicia sesión en Prime Video; la sesión se conserva entre aperturas. Para otra instancia independiente, con la misma sesión:

```bash
open -n macos/Primer.app
```

| Atajo | Acción |
|---|---|
| ⌘1 · ⌘2 · ⌘3 | Uno, dos o tres paneles |
| ⌥⌘H · ⌥⌘V | Paneles uno junto al otro (horizontal) · uno sobre otro (vertical) |
| ⌥⌘P | Con un solo panel, proporción de la ventana en secuencia: 16:9 → 1.85:1 → 2.35:1 → 2.39:1 → 2.40:1 → 16:9 (deshabilitada con dos o tres paneles) |
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
shared/    páginas locales de prueba (shared/fixtures/), ícono (shared/assets/) y su script (shared/scripts/)
openspec/  especificaciones y cambios: el plan de trabajo
```

## Cómo se trabaja

Este proyecto se desarrolla con especificaciones (OpenSpec) y con una persona que valida lo que solo una persona puede juzgar, como si el partido reproduce o cómo se ve. Para colaborar lee `AGENTS.md`.

## Licencia

GPLv3. Consulta `LICENSE`. Las marcas son de sus dueños (`NOTICE.md`).
