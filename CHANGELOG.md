# Historial de cambios

**Nota:** Todas las fechas están en zona horaria CST de Ciudad de México (UTC-6).

<!-- markdownlint-disable MD013 MD024 MD022 MD032 -->

## [2026-10-20] - Arranque del repositorio

- docs: se actualizan `README.md` (se quita el aviso de «en especificación» y se documentan requisitos, compilación, atajos, autoprueba y diagnóstico) y el cambio `add-macos-viewer`: los paneles quedan sin hueco (propuesta, diseño y especificaciones de `panes` y `selftest`), se marcan como hechas las tareas 4.2, 4.4, 5.1, 6.1 y 6.2 y se registran en `design.md` las validaciones del mantenedor, las mediciones de las tareas 5.1 y 6.1, el límite de reproducciones observado y el plan de las pruebas finales
- test: se agrega la página de prueba `shared/fixtures/form.html`, con campos de correo y contraseña de mentira, para comprobar que el registro de diagnóstico no contiene el contenido de los campos
- feat: se amplía `macos/Primer.swift` con los paneles pegados y sin hueco (cada uno mide la mitad del ancho y toda la altura de la ventana), el menú con los atajos de ⌘ y la recarga del panel con foco, el modo `--debug` sin datos personales y las comprobaciones de la autoprueba de atajos, sesión, recarga y diagnóstico
- docs: se actualizan en `add-macos-viewer` la propuesta, el diseño, la especificación de `panes` y las tareas: se agrega el requisito del clic que solo da el foco, se decide el guardián de audio en JavaScript, se registran las mediciones y validaciones de las tareas 2.3 a 4.4 (ventana, paneles, audio por foco) y se marcan como hechas las tareas 2.3, 3.1 a 3.4, 4.1 y 4.3
- feat: se amplía `macos/Primer.swift` con la ventana sin bordes (franja de arrastre, ⌥ + arrastrar, doble clic, proporción 16:9, rellenar y centrar, siempre encima), uno y dos paneles con hueco de 8 px y segundo panel a demanda, audio por foco con guardián de JavaScript, clic que solo da el foco al panel sin foco, y la autoprueba `--selftest` sin red ni cuenta
- test: las páginas de prueba `media.html` y `unmutes.html` ahora reproducen con volumen 0 para que la autoprueba no suene, y cuentan los eventos `mousedown` que llegan a la página mediante `mouseDowns()`
- test: se agregan las páginas de prueba de medios `shared/fixtures/media.html` (elemento `video` con una pista de audio breve) y `shared/fixtures/unmutes.html` (reactiva el audio de sus medios de forma periódica), y se marcan como hechas las tareas 2.1 y 2.2 en `tasks.md`
- refactor: se retiran el script `shared/fill-fullscreen.js` y las tres páginas de prueba de pantalla completa (`player.html`, `rewrites-classes.html` y `nested.html`), que ya no hacen falta, y se quita de `.gitignore` la línea de la copia del script en el paquete
- docs: se registra en `design.md` el resultado de la tarea 1.4 (el botón de pantalla completa del reproductor abre otro escritorio en pantalla completa y Esc regresa a la ventana de Primer, sin intervención de Primer), se marca como hecha en `tasks.md` y se actualiza la pregunta abierta sobre desactivar la pantalla completa del sistema con dos paneles
- docs: se registra en `design.md` la validación de las tareas 1.3 (dos instancias de Primer reproducen a la vez sin que Prime Video rechace nada; el límite real no se midió) y 1.4 (parcial: el reproductor se ajusta solo a la ventana y falta probar su botón de pantalla completa y los dos paneles), y se marca como hecha la tarea 1.3 en `tasks.md`
- docs: se reorienta `add-macos-viewer`: se elimina la especificación `fullscreen-emulation` (el reproductor de Prime Video llena la ventana por sí mismo y Primer ya no sobrescribe la pantalla completa), el centro del trabajo pasa al audio por foco (se silencia el panel sin foco), se ajustan las especificaciones de reproducción, paneles, diagnóstico y autoprueba, y se actualizan propuesta, diseño, tareas, `README.md`, `AGENTS.md` y `openspec/config.yaml`
- docs: se marcan como hechas las tareas 1.1, 1.2, 2.1 y 2.2 de `add-macos-viewer`, y se registra en `design.md` la validación de la prueba de reproducción (Prime Video reproduce un partido de la NBA con el sufijo de Safari en el *user agent*), junto con la pregunta abierta sobre mantener al día la versión de Safari
- feat: se agrega el script de pantalla completa `shared/fill-fullscreen.js` (heredado de DAZNer, con los ganchos `__primerDebug`, `__primerLog` y `__pane`) y tres páginas de prueba en `shared/fixtures/` (reproductor simulado, reescritura de clases y contenedores anidados)
- feat: se agrega el visor de macOS en `macos/` (`Primer.swift` sobre `WKWebView` y `build.sh`) con el sufijo de Safari en el *user agent*, necesario para que Prime Video reproduzca
- docs: se agrega el historial de cambios con la primera entrada
- docs: se agrega el cambio `add-macos-viewer` de OpenSpec con propuesta, diseño, tareas y ocho especificaciones (reproducción, paneles, pantalla completa, ventana sin bordes, sesión, atajos, diagnóstico y autoprueba)
- docs: se agregan README, guía para agentes (`AGENTS.md`, `CLAUDE.md`) y aviso de marcas (`NOTICE.md`)
- chore: se configuran los comandos y *skills* de OpenSpec para Claude Code y la configuración de `openspec/`
- chore: se agregan la licencia GPLv3, `.editorconfig`, `.gitignore` y los directorios `shared/` y `openspec/specs/`
