# Proposal

## Why

Ver los canales deportivos de Prime Video (hoy NBA League Pass; MLB.TV más adelante) obliga a usar una pestaña del navegador, sin una forma de acomodar dos partidos ni de llenar solo la ventana con el reproductor. Prime Video, a diferencia de DAZN, no trae vista múltiple nativa. Primer propone una aplicación de macOS sin bordes que abra el sitio oficial, ofrezca hasta dos paneles independientes, y deje que el reproductor llene por sí mismo la ventana o el panel, con el audio del panel sin foco silenciado, para ver dos partidos a la vez en una ventana 32:9.

El proyecto parte de DAZNer, que ya resolvió el mismo problema con otro servicio. De allí se hereda el comportamiento esperado, expresado como especificaciones, y la forma de trabajar. **Lo que se descubrió de DAZN se trata como hipótesis**: Prime Video usa otra página, otro reproductor y probablemente otro DRM en el motor web.

## What Changes

- Añadir la versión de macOS en `macos/`, escrita en Swift sobre `WKWebView`, que abre el sitio oficial de Prime Video.
- Definir el comportamiento esperado en siete capacidades: `window-chrome`, `panes`, `playback`, `session`, `shortcuts`, `diagnostics` y `selftest`.
- No sobrescribir la pantalla completa: según el mantenedor, al reproducir el reproductor de Prime Video llena la ventana por sí mismo (por confirmar en la tarea 1.4 y con dos paneles).
- Mantener silenciado el panel sin foco aunque su reproductor intente reactivar el audio, que es el centro del trabajo.
- Añadir un modo de autoprueba (`--selftest`) que comprueba el audio por foco y los paneles contra páginas locales, sin cuenta ni red, para que el agente pueda verificar por su cuenta lo que no depende de Prime Video.
- Empezar con una prueba de reproducción que valida una persona, y que decide si se sigue.

Fuera del alcance: emular o sobrescribir la pantalla completa, versiones para Windows y Linux, instalador, firma de código, publicación, más de dos paneles, cualquier forma de eludir el DRM, los controles de acceso o el límite de transmisiones simultáneas de la cuenta, y cualquier servicio distinto de Prime Video.

## Capabilities

### New Capabilities

- `window-chrome`: ventana sin bordes, movimiento, proporción fija, rellenar y centrar, y siempre encima.
- `panes`: uno o dos paneles juntos y sin hueco, segundo panel a demanda, audio por foco y un clic que solo da el foco.
- `playback`: qué carga la aplicación, que el reproductor llena la ventana o el panel por sí mismo, y las prohibiciones sobre el DRM y los límites de la cuenta.
- `session`: sesión persistente, sin contraseñas y varias instancias.
- `shortcuts`: atajos de teclado y edición de texto.
- `diagnostics`: modo de diagnóstico opcional.
- `selftest`: autoprueba verificable sin cuenta ni red.

### Modified Capabilities

## Impact

- Nueva carpeta `macos/` con el código de Swift y su script de compilación.
- Nueva carpeta `shared/` con las páginas locales de prueba de la autoprueba.
- Requiere una Mac para compilar y probar. La reproducción y la apariencia solo las puede validar una persona con una suscripción propia a un canal deportivo de Prime Video (hoy NBA League Pass).
- La prueba de reproducción (grupo 1 de las tareas) no depende de nada y puede hacerse desde ya.
