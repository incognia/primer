---
title: "Primer"
description: "Visor nativo y mínimo de los canales deportivos de Prime Video (NBA League Pass) para macOS con WebKit: ventana sin bordes, hasta tres paneles con audio por foco y proporciones de cine."
---

# Primer

*Última modificación: 21 de octubre de 2026, 01:39 (CST)*

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.html)
[![Platform: macOS](https://img.shields.io/badge/platform-macOS-lightgrey.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-F05138?logo=swift&logoColor=white)](https://www.swift.org/)
[![WebKit](https://img.shields.io/badge/WebKit-WKWebView-informational.svg)](https://webkit.org/)

Visor nativo y mínimo de los canales deportivos de Prime Video (hoy NBA League Pass; MLB.TV más adelante) para macOS, hecho con WebKit. Abre el sitio oficial en una ventana sin bordes, con uno, dos o tres paneles, para ver varios partidos a la vez (dos en una ventana 32:9) con el audio del panel sin foco silenciado. Proyecto personal de Rodrigo Álvarez (@incognia).

Primer **no es un producto de Amazon, Prime Video, la NBA ni la MLB**. Consulta [NOTICE.md](NOTICE.md).

## Estado

| Plataforma | Estado | Motor web |
|---|---|---|
| macOS | Disponible | WebKit (`WKWebView`) |

Por ahora solo existe la versión de macOS. Está construida y validada por su autor: ventana, paneles (de uno a tres, en horizontal o vertical), audio por foco, sesión y proporciones de cine. Dos cosas quedan sin cerrar: el 2.35:1 se aceptó sin probarlo con una película real, y el reproductor se refrescó al pasar de la disposición horizontal a la vertical, un pendiente que se revisará después (véase [AGENTS.md](AGENTS.md)).

El plan, sus decisiones y el registro de lo que se validó están archivados, un cambio por carpeta, en `openspec/changes/archive/`:

- [`add-macos-viewer`](openspec/changes/archive/2026-10-20-add-macos-viewer/design.md): la ventana, los paneles, el audio por foco, la sesión y la autoprueba.
- [`add-third-pane-and-layouts`](openspec/changes/archive/2026-10-20-add-third-pane-and-layouts/design.md): el tercer panel y las disposiciones horizontal y vertical.
- [`add-cinema-ratios`](openspec/changes/archive/2026-10-21-add-cinema-ratios/design.md): las proporciones de cine con un solo panel.

## Por qué WebKit

- Prime Video reproduce dentro de `WKWebView` si el motor se identifica con el sufijo de Safari en el *user agent*; con la identificación predeterminada del motor lo rechazó.
- Es un solo archivo de Swift que se compila con `swiftc`, sin Xcode y sin dependencias.

## Requisitos

- **macOS con Apple Silicon.** Probado en macOS 26.7.1 con un Mac `arm64`; no se ha probado en otras versiones ni en Intel.
- **Swift.** Basta con las Herramientas de línea de comandos (`xcode-select --install`); no hace falta Xcode completo. Probado con Swift 6.4.
- **Una suscripción propia y válida** a un canal deportivo de Prime Video (hoy NBA League Pass). Primer no lee, guarda ni registra contraseñas.
- **Safari instalado.** Primer se identifica con el sufijo de Safari (`Version/27.0 Safari/605.1.15`, fijo en `macos/Primer.swift`). Si Prime Video deja de reproducir tras actualizar Safari, ese número es lo primero que hay que revisar.

## Compilar (macOS)

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

## Estructura del repositorio

```text
Primer/
├── macos/     código de la versión de macOS y su paquete Primer.app
├── shared/    páginas de prueba de la autoprueba (fixtures/), ícono (assets/) y su script (scripts/)
├── openspec/  especificaciones del comportamiento (specs/) y cambios (changes/)
├── AGENTS.md  guía para agentes que trabajan en el repositorio
└── ...        README, CHANGELOG, NOTICE y LICENSE
```

## Desarrollo con OpenSpec

El trabajo se planea con [OpenSpec](https://openspec.dev/): las especificaciones de `openspec/specs/` describen el comportamiento de la versión de macOS y son el contrato del proyecto, y cada cambio se propone, se aplica y se archiva en `openspec/changes/`. Hoy no hay cambios activos. Lo que solo una persona puede juzgar (si el partido reproduce, cómo se ve, si el panel sin foco queda en silencio) lo valida el mantenedor, y queda anotado en el diseño de cada cambio. El autor trabaja solo y directo en `main`. Para colaborar o entender el flujo, lee primero [AGENTS.md](AGENTS.md).

## Uso

Abre `macos/Primer.app` e inicia sesión en Prime Video; la sesión se conserva entre aperturas. Para otra instancia independiente, con la misma sesión:

```bash
open -n macos/Primer.app
```

- **Mover la ventana:** arrastra desde la franja invisible del borde superior (14 px) o mantén ⌥ Option y arrastra desde cualquier punto. El doble clic en la franja maximiza o restaura.
- **Redimensionar:** desde los bordes, con proporción fija: 16:9 con un panel, 32:9 con dos y 48:9 con tres (en horizontal); 16:18 y 16:27 en vertical.
- **Proporciones de cine:** con un solo panel, ⌥⌘P cambia la ventana en secuencia entre 16:9, 1.85:1, 2.35:1, 2.39:1 y 2.40:1 para que las películas panorámicas no dejen bandas negras. Con dos o tres paneles está deshabilitada, y al abrir otro panel la ventana vuelve a 16:9.
- **Paneles:** Prime Video no trae vista múltiple, así que Primer ofrece hasta tres paneles independientes, pegados, uno junto al otro (horizontal, la disposición al abrir) o uno sobre otro (vertical). Todos comparten la sesión, y la disposición no se recuerda entre aperturas. El panel nuevo se crea al elegirlo y se libera al volver a menos paneles.
- **Audio por foco:** con dos o tres paneles solo suena el que tiene el foco; los demás quedan silenciados, aunque su reproductor intente reactivar el sonido. Un silencio puesto a mano desde el reproductor se respeta.
- **El clic que da el foco no pausa:** un clic en el panel sin foco solo le pasa el foco y el audio, y no llega a la página. Con el foco puesto, un clic en el video sí lo pausa, como hace Prime Video.
- **Pantalla completa:** Primer no la toca. El reproductor de Prime Video llena por sí mismo la ventana o el panel, y su botón de pantalla completa usa la del sistema (Esc regresa).

| Atajo | Acción |
|---|---|
| ⌘1 · ⌘2 · ⌘3 | Uno, dos o tres paneles |
| ⌥⌘H · ⌥⌘V | Paneles uno junto al otro (horizontal) · uno sobre otro (vertical) |
| ⌥⌘P | Con un solo panel, proporción de la ventana en secuencia: 16:9 → 1.85:1 → 2.35:1 → 2.39:1 → 2.40:1 → 16:9 (deshabilitada con dos o tres paneles) |
| ⌘\` | Pasar el foco y el audio al siguiente panel |
| ⌘L | Abrir una dirección en el panel con foco |
| ⌘R | Recargar el panel con foco |
| ⌘H | Inicio de Prime Video en el panel con foco |
| ⌘F | Rellenar y centrar: la ventana más grande que cabe en la pantalla, con su proporción |
| ⌘T | Siempre encima |
| ⌘W · ⌘Q | Cerrar · Salir |
| ⌥ + arrastrar | Mover la ventana desde cualquier punto (también se arrastra desde el borde superior) |

## Autoprueba

```bash
macos/Primer.app/Contents/MacOS/Primer --selftest
```

Comprueba por sí misma la ventana, los paneles, las disposiciones, las proporciones de cine, el audio por foco, los atajos y el diagnóstico con páginas locales de `shared/fixtures/`. **No usa red ni cuenta, no toca tu sesión y no abre Prime Video**: imprime una línea por comprobación y termina con código 0 solo si todas pasaron. No sustituye la prueba con un partido real. Con `PRIMER_FIXTURES=<carpeta>` se usan otras páginas de prueba.

## Modo de diagnóstico

```bash
open -n macos/Primer.app --args --debug
```

Escribe `debug.log` junto a la aplicación (en `macos/`) y habilita el inspector web. Está apagado por omisión y no debe versionarse. Registra los eventos de audio (foco, silenciado y reactivaciones del reproductor) y de cada panel (tamaño, carga y descarga); de una dirección solo guarda servidor y ruta, nunca contraseñas, códigos ni el contenido de los campos.

## Notas

- Primer es un proyecto no oficial y no está afiliado a Amazon, Prime Video, la NBA ni la MLB. Consulta [NOTICE.md](NOTICE.md).
- La contraseña no se guarda. Solo se conserva la sesión de Prime Video, en `~/Library/WebKit/mx.org.faraday.primer`. El identificador de la aplicación es `mx.org.faraday.primer` (el dominio faraday.org.mx al revés).
- Primer no elude el límite de transmisiones simultáneas de la cuenta ni ninguna otra protección: si Prime Video rechaza una reproducción, la aplicación muestra lo que responda. Con la cuenta del autor, tres reproducciones a la vez funcionaron sin rechazo; el límite exacto, si lo hay, no se ha medido.
- La aplicación está firmada solo de forma local. Si macOS la bloquea, ábrela con clic derecho → Abrir.
- La búsqueda de Spotlight (⌘Espacio) encuentra `Primer.app` donde esté compilada, sin instalarla.

## Licencia

Primer es software libre y se distribuye bajo la licencia GPLv3. Consulta el texto completo en [LICENSE](LICENSE) y el aviso de proyecto no oficial y de marcas en [NOTICE.md](NOTICE.md).

<!-- licence:start -->

---

*Este proyecto fue elaborado por Rodrigo Álvarez (@incognia) y se distribuye bajo la licencia GPLv3. Para más detalles, consulta el archivo LICENSE.*

*Copyright © 2026, Rodrigo Ernesto Álvarez Aguilera. Este es software libre bajo los términos de la GNU General Public License v3.*

<!-- licence:end -->
