## Context

DAZNer ya resolvió el mismo problema para DAZN: una ventana sin bordes, uno o dos paneles y una pantalla completa que llena la ventana. Primer quiere lo mismo para los canales deportivos de Prime Video: hoy NBA League Pass y, más adelante, MLB.TV, que se contratan como canales dentro de Prime Video. Por eso el proyecto se construye sobre Prime Video y no se ata a un deporte. Hay dos diferencias de fondo:

- **Prime Video no trae vista múltiple.** En DAZN, la página resolvía varios partidos en una cuadrícula. Aquí, los paneles de Primer son la forma de ver dos partidos a la vez. Un panel mide 16:9 y dos paneles forman una ventana 32:9.
- **El reproductor y su DRM son otros.** Lo que se descubrió de DAZN (cómo pide la pantalla completa, qué reescribe, qué márgenes calcula) es una hipótesis hasta observarlo en Prime Video.

Este cambio se ejecuta con una persona en el ciclo: lo que solo una persona puede juzgar lo valida el mantenedor, y lo que el agente puede comprobar por sí mismo se comprueba con una autoprueba.

## Goals / Non-Goals

**Goals:**

- Mismo comportamiento que DAZNer, expresado como las especificaciones de este cambio.
- Que el agente pueda verificar por su cuenta todo lo que no dependa de Prime Video (`--selftest`), y que el humano valide lo demás con pasos exactos.
- Empezar por la prueba de reproducción y detenerse si falla.

**Non-Goals:**

- Windows y Linux, instalador, firma de código, tiendas.
- Más de dos paneles.
- Eludir el DRM, los controles de acceso o el límite de transmisiones simultáneas de la cuenta.
- Cualquier otro servicio distinto de Prime Video.

## Decisions

- **Repositorio aparte.** Primer vive en su propio repositorio, no en una rama de DAZNer: las marcas, las especificaciones y el reto abierto de DAZNer son de DAZN, y una rama larga divergiría de `main`. Si más adelante comparten mucho código, se extrae un núcleo común con datos en la mano.
- **Lenguaje y motor:** Swift sobre `WKWebView`, compilado con `swiftc`, como DAZNer. Es la única plataforma que se puede compilar y probar en la máquina del autor, y el motor web nativo de macOS usa el DRM del sistema.
- **Script de pantalla completa:** punto de partida, el de DAZNer (mismo autor, misma licencia), copiado a `shared/fill-fullscreen.js` con los ganchos renombrados a `window.__primerDebug`, `window.__primerLog` y `window.__pane`, sin cambiar su lógica. Se adapta solo después de observar el reproductor de Prime Video con `--debug`.
- **Proporción y hueco:** 16:9 con un panel, 32:9 con dos, y un hueco de 8 px dentro del ancho de la ventana. El hueco se hereda de DAZN, donde nacía de la cuadrícula de su *multiview*; aquí no hay cuadrícula, y se valida visualmente.
- **Autoprueba:** `--selftest` abre páginas locales (`shared/fixtures/`) que simulan un reproductor, mide con JavaScript lo que el script hace y revisa que la ventana no entre en pantalla completa del sistema. No usa red ni cuenta. Sirve para que el agente verifique los cambios de pantalla completa y de paneles sin una persona, y no sustituye la validación humana.
- **Sesión:** almacén de datos persistente del motor web, compartido entre paneles e instancias.
- **User agent:** la identificación real de `WKWebView` (el WebKit del sistema) con el sufijo de Safari, `Version/27.0 Safari/605.1.15`, añadido con `applicationNameForUserAgent`; la versión es la de Safari de la Mac del mantenedor. Con la identificación predeterminada Prime Video respondió «Video no disponible» y Safari sí reproducía (tarea 1.2, 2026-10-20); con el sufijo reproduce. El motor no cambia: sigue siendo WebKit, y no se oculta ni se evita ninguna protección.
- **Dirección de inicio:** una sola constante en el código, para cambiarla sin tocar el resto (ver preguntas abiertas).
- **Humano en el ciclo:** cada tarea lleva la marca [AUTO] (la ejecuta y verifica el agente) o [HITL] (la valida el mantenedor). El agente prepara los pasos y el resultado esperado; el humano responde; el agente lo anota en el registro de abajo y solo entonces marca la tarea.

## Risks / Trade-offs

- **Prime Video puede no reproducir dentro de `WKWebView`.** Puede rechazar la sesión o el DRM en un motor embebido. Se mitiga con la prueba de reproducción como primera tarea y con la decisión explícita de detener el trabajo si falla.
- **Límite de transmisiones simultáneas.** Dos paneles o dos instancias son dos transmisiones, y la cuenta puede no permitirlas. No se elude: se mide en la tarea 1.3 y, si no se puede, el modo de dos paneles queda como mostrar lo que Prime Video responda.
- **El script puede no servir tal cual.** El reproductor de Prime Video puede pedir la pantalla completa de otra forma. Se mitiga observando antes de adaptar, y con la autoprueba para no romper lo que ya funciona.
- **La autoprueba puede dar falsa confianza.** Una página de prueba no es Prime Video. Por eso declara en su salida que no probó Prime Video y por eso la validación final es humana.
- **Inicio de sesión con pasos extra.** Los códigos de verificación o las llaves de acceso pueden abrir ventanas o flujos que un motor embebido no maneja. Se observa en la tarea 1.2.
- **Contenido con restricciones por región.** Las restricciones de transmisión de cada liga dependen de la región y la cuenta. Están fuera del alcance de Primer, que solo muestra lo que el sitio ofrezca.

## Open Questions

- ¿Cuál es la dirección de inicio correcta para la cuenta del mantenedor? Depende de la región y del canal. Se resuelve en la tarea 1.2.
- ¿El botón de pantalla completa del reproductor de Prime Video usa la API estándar (`requestFullscreen`)? ¿Hay más de un botón? Lo responde la tarea 1.4 y se confirma en la 5.1.
- ¿Cuántas transmisiones simultáneas permite la cuenta del mantenedor? Lo responde la tarea 1.3.
- ¿El hueco de 8 px entre paneles se ve bien en Prime Video, o conviene otro valor? Lo responde la tarea 4.2.
- ¿Cómo se silencia un panel sin tocar el reproductor? En DAZNer se hizo con JavaScript sobre los elementos de video; aquí se decide tras la prueba de reproducción.
- ¿Cómo se mantiene al día la versión de Safari del sufijo del *user agent*? Hoy está fija en el código y se desactualizará; se decide si se lee en ejecución o se revisa a mano.
- ¿Hace falta un ícono desde el principio? Hoy no hay ícono; se diseña uno propio antes de publicar.

## Registro de validación

Aquí el agente anota lo que validó el mantenedor: fecha, tarea, qué se probó y qué respondió, con sus palabras cuando algo falla. Una fila nueva por validación.

| Fecha | Tarea | Qué se probó | Resultado del mantenedor |
|---|---|---|---|
| 2026-10-20 | 1.2 | Primer 1.1 con el *user agent* predeterminado de `WKWebView`; reproducir un video de Prime Video | **Resultado parcial, sin aprobar.** El mantenedor envió una captura: «Video no disponible. Tenemos problemas para reproducir este video. Para obtener ayuda, dirígete a www.primevideo.com/help.» con un botón «Aceptar». Falta aclarar qué video era, si había sesión iniciada, si había otra instancia abierta y si el mismo video reproduce en Safari con la misma cuenta. |
| 2026-10-20 | 1.2 (control) | El mismo tipo de video, en Safari de la misma Mac y con la misma cuenta | **Reproduce en Safari.** Antes del video, Prime Video muestra «Información de contenido en directo» con botones «Cerrar reproductor» y «Continuar» (casilla «No volver a mostrar este mensaje»). Con el video en marcha, la pestaña muestra el ícono de audio activo y la captura sale en negro, como es normal con DRM. Conclusión: la cuenta, la región y el contenido no son la causa; el fallo está en el motor embebido de Primer (hipótesis a probar: el *user agent*). |
| 2026-10-20 | 1.2 (resultado) | Primer con el sufijo de Safari en el *user agent*, mismo partido que en Safari | **Reproduce.** El mantenedor confirmó «ya reproduce» y envió una foto del celular con un partido de la NBA en curso dentro de la ventana de Primer. La calidad máxima, la confirmación explícita del audio y la dirección (URL) del partido o del canal **no se reportaron**. Observación: la ventana muestra botones y barra de título, y no mantiene proporción; es lo previsto para la tarea 1.1 y se resuelve en el grupo 3. |
