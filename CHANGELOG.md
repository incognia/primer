# Historial de cambios

**Nota:** Todas las fechas están en zona horaria CST de Ciudad de México (UTC-6).

<!-- markdownlint-disable MD013 MD024 MD022 MD032 -->

## [2026-10-20] - Arranque del repositorio

- docs: se marcan como hechas las tareas 1.1, 1.2, 2.1 y 2.2 de `add-macos-viewer`, y se registra en `design.md` la validación de la prueba de reproducción (Prime Video reproduce un partido de la NBA con el sufijo de Safari en el *user agent*), junto con la pregunta abierta sobre mantener al día la versión de Safari
- feat: se agrega el script de pantalla completa `shared/fill-fullscreen.js` (heredado de DAZNer, con los ganchos `__primerDebug`, `__primerLog` y `__pane`) y tres páginas de prueba en `shared/fixtures/` (reproductor simulado, reescritura de clases y contenedores anidados)
- feat: se agrega el visor de macOS en `macos/` (`Primer.swift` sobre `WKWebView` y `build.sh`) con el sufijo de Safari en el *user agent*, necesario para que Prime Video reproduzca
- docs: se agrega el historial de cambios con la primera entrada
- docs: se agrega el cambio `add-macos-viewer` de OpenSpec con propuesta, diseño, tareas y ocho especificaciones (reproducción, paneles, pantalla completa, ventana sin bordes, sesión, atajos, diagnóstico y autoprueba)
- docs: se agregan README, guía para agentes (`AGENTS.md`, `CLAUDE.md`) y aviso de marcas (`NOTICE.md`)
- chore: se configuran los comandos y *skills* de OpenSpec para Claude Code y la configuración de `openspec/`
- chore: se agregan la licencia GPLv3, `.editorconfig`, `.gitignore` y los directorios `shared/` y `openspec/specs/`
