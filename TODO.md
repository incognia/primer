# Pendientes

*Última modificación: 21 de octubre de 2026, 01:49 (CST)*

Vista corta de lo que falta. Hoy no hay cambios activos en OpenSpec: lo que sigue son pendientes de revisión, decisiones por tomar y cosas sin probar. El detalle de lo ya hecho está en `openspec/changes/archive/` y las preguntas que quedaron abiertas al archivarlo, en la sección «Open Questions» del diseño de [`add-macos-viewer`](openspec/changes/archive/2026-10-20-add-macos-viewer/design.md). Si este archivo y OpenSpec discrepan, manda OpenSpec.

## Pendientes de revisión

- [ ] **Refresco del reproductor al pasar de horizontal a vertical (⌥⌘V).** Con paneles reproduciendo, el reproductor se refrescó aunque cada panel conserva su tamaño; lo observó el autor el 2026-10-20 al validar `add-third-pane-and-layouts`. El registro archivado de ese cambio dice que el primer panel seguía sin interrupción, y no coincide. Cambiar solo el alto de la ventana con ⌥⌘P no refrescó. Sin determinar: qué lo causa, si afecta a uno o a los dos paneles y si pasa también de vertical a horizontal. Decidido por el autor el 2026-10-21: no se corrige por ahora y no se toca sin que lo pida.
- [ ] **El 2.35:1 no se probó con una película real.** El autor no encontró una incluida en su cuenta y lo aceptó el 2026-10-21 por la evidencia de 1.85:1, 2.39:1 y 2.40:1. Falta una película en 2.35:1 para verificarlo.
- [ ] **Mantener al día la versión de Safari del *user agent*.** Hoy está fija en `Version/27.0 Safari/605.1.15` en `macos/Primer.swift` y se desactualizará. Si Prime Video deja de reproducir tras actualizar Safari, es lo primero que hay que revisar. Decidir si se lee en ejecución desde `Safari.app` (con `27.0` de respaldo) o se revisa a mano; si se lee, es un cambio nuevo de OpenSpec.

## Por probar

- [ ] **MLB.TV**, que el autor planea contratar por la misma vía que NBA League Pass.
- [ ] **Otras versiones de macOS y Macs con Intel.** Primer se probó en macOS 26.7.1 con un Mac `arm64`.
- [ ] **Límite exacto de transmisiones simultáneas.** Con tres paneles, la cuenta del autor permitió tres reproducciones a la vez (un partido de OKC, uno de Necaxa y una película); el límite, si lo hay, no se ha medido.

## Preguntas abiertas

- ¿Se puede redondear las esquinas de un panel sin que el video protegido de Prime se ponga en negro? Es la condición para probar un hueco transparente entre paneles con bordes que concuerden con los de la ventana.
- ¿Conviene que un clic en la superficie del video nunca pause y solo lo haga el botón de reproducción/pausa? Hoy el reproductor de Prime pausa con un clic en cualquier parte; requeriría interceptar clics dentro de la página y conocer su estructura.

## Hecho

- [x] Versión de macOS con WebKit: ventana sin bordes, proporción fija, paneles con audio por foco, clic de foco, rellenar y centrar, sesión persistente, modo `--debug` y autoprueba (`add-macos-viewer`).
- [x] Tercer panel y disposiciones horizontal y vertical (`add-third-pane-and-layouts`).
- [x] Proporciones de cine con un solo panel: 1.85:1, 2.35:1, 2.39:1 y 2.40:1 (`add-cinema-ratios`).
- [x] Licencia GPLv3, aviso de marcas e ícono propio.
- [x] README con la estructura de DAZNer y enlaces que resuelven; About del repositorio en GitHub.
